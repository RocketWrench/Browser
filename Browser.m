classdef Browser < handle
    % Browser - an implementation of JCEF for matlab
    %  https://bitbucket.org/chromiumembedded/java-cef/src/master/

    properties(Access = public, Dependent = true, SetObservable, AbortSet)
        % URL: Current location. Character vector.
        URL
        % Title: Current web page title. Character array.
        Title
        % Favicon: Favicon of current webpage, the defualt (globe) icon if
        % favicon is not retrivable or null. javax.swing.ImageIcon.
        Favicon
        % IsLoading: Flag indicating if the web page is loading (true) or
        % has completed loading (false). boolean.
        IsLoading
        % CanGoBack: Flag indicating if the focused browser can go back.
        % boolean.
        CanGoBack
        % CanGoForward: Flag indicating if focused browser can go forward.
        % boolean.
        CanGoForward
        % ErrorCode: Last error code encountered. Character array.
        ErrorCode
        % StatusMessage: Last status message, typicaly the text of the last
        % hypertext that was moused over. Character array
        StatusMessage        
    end

    properties(Access = public, Dependent = true)
        % BrowserID: Focused browsers identifier. Scalar, double.
        BrowserID
        % RetriveFavicon: Flag idicating if a site's favicon is retrieved.
        % boolean.
        RetriveFavicon
        % EnableContextMenu: Flag indicating if a context menu is shown on 
        % right click. Context menu is content aware, if content is an
        % image that can be opened in matlab, the option to open
        % image (without downloading) in imtool/imshow is presented,
        % otherwise, the option to download image to file is presented.
        % An option to view page source code in a Matlab Editor is
        % provided (saving the Editor instance as an httml file will enable
        % viewing the source code with proper syntax). boolean. 
        EnableContextMenu
        % Flag idicating of an address panel is shown above browser
        EnableAddressPane
        % Flag idicating if debug messages are printed to the command
        % window
        ShowDebug
    end

    properties(Access = protected)
        
        position_(1,4) double = Browser.DEFAULT_POSITION;

        client_;        

        browsers_ = java.util.HashMap;

        focusedBrowserID_(1,1) int32 = -1;
        focusedBrowser_;

        url_(1,:) char = Browser.DEFAULT_URL;

        favicon_ = [];
        favIconMap_;

        title_(1,:) char  = '';
        statusMessage_(1,:) char = '';
        consoleMessage_(1,:) char = '';

        errorCode_(1,:) char = '';
        errorMsg_(1,:) char  = '';
        
        clientListeners_;
        handleListeners_;
        browserPanelListeners_;
        displayHandlerListener_;
        loadHandlerListener_;
        contextMenuHandlerListener_;
    end

    properties(Access = protected)
        % flags
        overrideOSR_(1,1) logical = false;
        useOSR_(1,1) logical = isunix();
        isTransparent_(1,1) logical = false;
        isLoading_(1,1) logical = false;
        canGoBack_(1,1) logical = false;
        canGoForward_(1,1) logical = false;
        hasFirstBrowserBeenCreated_(1,1) logical = false;
        retrieveFavicon_(1,1) logical = false;
        isContextMenuEnabled_(1,1) logical = false
        enableAddressPane_(1,1) logical = false;
        showDebug_(1,1) logical = false;
    end

    properties(Access = public, Constant = true, Hidden = true)

        DEFAULT_URL = 'https://www.google.com/';
        DEFAULT_POSITION = [0,0,1,1];
        BLANK_URL = 'about:blank';
        NO_ERROR = [web.ErrorCode.ERR_NONE.toString.char,'(',int2str(web.ErrorCode.ERR_NONE.getCode),')'];
        GENERIC_ICON = com.mathworks.common.icons.IconEnumerationUtils.getIcon('web_globe.png');
    end

    events

        AddressChanged
        TitleChanged
        IconChanged
        LoadingStateUpdated
        CanGoBackUpdated
        CanGoForwardUpdated
        StatusMessageUpdated
        ConsoleMessageUpdated
    end

    methods

        function this = Browser( URL, parent, varargin )                     

            if nargin
                this.url_ = this.validateURL(URL);
                this.initialize();
                
                if nargin > 2
                    this.parseInputs(varargin);
                end

                if nargin > 1
                    this.install(parent,this.position_);
                end                
            end           
        end

        function delete( this )

            try delete(this.clientListeners_); catch; end
            try delete(this.handleListeners_); catch; end
            try delete(this.loadHandlerListener_); catch; end
            try delete(this.displayHandlerListener_); catch; end
            try delete(this.contextMenuHandlerListener_); catch; end
            try this.client_.dispose(); catch; end          
        end
    end

    methods(Access = public)

        function varargout = install( this, hparent, position )
            % install browser panel in a hg parent            

            narginchk(1,3)
            nargoutchk(0,3);             
            
            cefBrowser = this.getFocusedBrowser();
            
            browserPanel = handle(javaObjectEDT('web.ui.BrowserPanel',cefBrowser,this.enableAddressPane_),'CallbackProperties');
            
            this.loadHandlerListener_ = addlistener(browserPanel.getLoadHandlerCallback,'delayed',@this.onClientAction);
            this.displayHandlerListener_ = addlistener(browserPanel.getDisplayHandlerCallback,'delayed',@this.onClientAction);

            container = [];                         

            if nargin > 1
                
                assert(~isempty(hparent) & isvalid(hparent),...
                    'webBrowser:InvalidParent',...
                    'hparent must be a valid graphics handle')

                if nargin == 3
                    this.position_ = position;
                end   

                drawnow();
                
                container = this.createJavaWrapperPanel(hparent,browserPanel,this.position_);
                drawnow()

                this.installHandleListener(hparent,cefBrowser);
            end           

            if nargout
                if nargout == 1
                    varargout{1} = browserPanel;
                elseif nargout == 2
                    varargout{1} = browserPanel;
                    varargout{2} = this.focusedBrowser_;
                else
                    varargout{1} = browserPanel;
                    varargout{2} = this.focusedBrowser_; 
                    varargout{3} = container; 
                end
            end
        end

        function cefBrowser = new( this, URL )

            if nargin > 1
                this.url_ = this.validateURL(URL);
            end
            osr = this.useOSR_ | this.overrideOSR_;
            this.focusedBrowser_ = this.getNewBrowser();
            this.focusedBrowserID_ = this.focusedBrowser_.getIdentifier();
            cefBrowser = this.focusedBrowser_;
        end

        function load( this, URL)
            
            this.loadURL(URL,this.focusedBrowser_);
        end

        function loadURL(this, URL, browser)
        
            narginchk(1,3)

            if nargin < 3
                browser = this.focusedBrowser_;
            end

            if nargin == 1
                URL = this.DEFAULT_URL;
            end
            browser.stopLoad();
            this.url_ = this.validateURL(URL);
            browser.loadURL(this.url_);
        end

        function loadString( this, strContent, mimeType, browser )

            narginchk(2,4)

            isDataURI = false;

            strContent = convertStringsToChars(strContent);

            if isfile(strContent)
                cellstr = readlines(strContent,'EmptyLineRule','skip','WhitespaceRule','trim');
                strContent = char(join(cellstr));
            end            

            switch nargin
                case 2
                    browser = this.focusedBrowser_;

                    if startsWith(strContent,'data','IgnoreCase',true)
                        isDataURI = strcmp(strContent(1:5),'data:');
                    end
                    mimeType = 'text/html';                    
                case 3
                    isDataURI = isempty(mimeType);
                    browser = this.focusedBrowser_;
                case 4
                    isDataURI = isempty(mimeType);
            end
            browser.stopLoad();
            if isDataURI
                browser.loadURL(strContent);
            else
                browser.loadURL(this.createDataURI(mimeType,char(strContent)));
            end

            drawnow();
        end

        function alert( this, msg )
            
            code = "alert('" + msg + "');";
            this.executeJavaScript(code,this.url_,1);
        end

        function prompt( this, promptstr, defaultval )

            code = "'var value = prompt('" + promptstr   + "', '" + defaultval + "');";
            this.executeJavaScript(code,this.url_,1);
        end

        function executeJavaScript( this, code, url, lineno )
            narginchk(2,4)

            code = convertStringsToChars(code);
            
            if isfile(code)
                cellstr = readlines(code,'EmptyLineRule','skip','WhitespaceRule','trim');
                code = char(join(cellstr));
            end 

            switch nargin
                case 2
                    url = this.url_;
                    lineno = 0;
                case 3
                    lineno = 0;
            end
            this.focusedBrowser_.executeJavaScript(code,url,lineno);
        end

        function goBack( this, browser )
            
            if nargin == 1
                browser = this.focusedBrowser_;
            end

            browser.goBack();
        end

        function goForward( this, browser )
            
            if nargin == 1
                browser = this.focusedBrowser_;
            end

            browser.goForward();
        end 

        function reload( this, ignoreCache )

            if nargin == 1
                this.focusedBrowser_.reload();
            else
                if ignoreCache
                    this.focusedBrowser_.reloadIgnoreCache();
                else
                    this.focusedBrowser_.reload();
                end
            end
        end

        function showDevTools( this, browser ) %#ok<INUSD> 
            % CefApp is set up by Matlab, debug port needs to be something
            % other than zero for devtools to work
        end

        function icon = getGenericIcon( this )
            icon = this.GENERIC_ICON;
        end
    end

    methods

        function val = get.URL( this )
            val = this.url_;
        end

        function val = get.Title( this )
            val = this.title_;
        end 

        function val = get.CanGoBack( this )
            val = this.canGoBack_;
        end  

        function val = get.CanGoForward( this )
            val = this.canGoForward_;
        end 

        function val = get.ErrorCode( this )
            val = this.errorCode_;
        end         

        function val = get.BrowserID( this )
            val = this.focusedBrowser_.getIdentifier();
        end

        function val = get.Favicon( this )
                val = this.favicon_;
        end

        function val = get.IsLoading( this )
            val = this.isLoading_;
        end

        function val = get.RetriveFavicon( this)
            val = this.retrieveFavicon_;
        end

        function set.RetriveFavicon( this, val )
            this.retrieveFavicon_ = logical(val);
            if val && isempty(this.favIconMap_)
                this.favIconMap_ = java.util.HashMap();
            end
        end

        function val = get.StatusMessage( this )
            val = this.statusMessage_;
        end

        function val = get.EnableContextMenu( this )
            val = this.isContextMenuEnabled_;
        end

        function set.EnableContextMenu( this, val )
            val = logical(val);
            this.setContextMenuHandler();
        end

        function val = get.EnableAddressPane( this )
            val = this.enableAddressPane_;
        end

        function set.EnableAddressPane( this, val )
            val = logical(val);
            if ~(this.enableAddressPane_ & val) %#ok<AND2> 
                this.enableAddressPane_ = val;
            end
        end 

        function val = get.ShowDebug( this )
            val = this.showDebug_;
        end

        function set.ShowDebug( this, val )
            this.showDebug_ = logical(val);
        end
    end

    methods(Access = public, Hidden = true)

        function browsers = getAllBrowsers( this )
            browsers = this.getFieldValueByName(this.client_,'browser_');
            try browsers = browsers.values().toArray(); catch; end
        end

        function browser = getFocusedBrowser( this )
            browser = this.focusedBrowser_;
            if isempty(browser)
                browser = this.new();
            end
        end
    end

    methods(Access = protected)

          function parseInputs( this, args )

            parser = inputParser();

            addParameter(parser,'Position',this.DEFAULT_POSITION );
            addParameter(parser,'RetriveFavicon', false);
            addParameter(parser,'EnableContextMenu', false);
            addParameter(parser,'EnableAddressPane', false);
            addParameter(parser,'ShowDebug', false);

            parse(parser,args{:});
            
            this.position_ = parser.Results.Position;
            this.retrieveFavicon_ = parser.Results.RetriveFavicon;
            this.isContextMenuEnabled_ = parser.Results.EnableContextMenu;
            this.enableAddressPane_ = parser.Results.EnableAddressPane;
            this.showDebug_ = parser.Results.ShowDebug;
        end

        function initialize( this)

            this.configureClient(); 
            this.hasFirstBrowserBeenCreated_ = true;
            this.focusedBrowser_ = this.getNewBrowser();
            this.focusedBrowserID_ = this.focusedBrowser_.getIdentifier();            
        end
        
        function configureClient( this )

            if isempty(this.client_)
                this.client_ = this.getClient();                
            end
            this.installClientListeners();
        end
        
        function browser = getNewBrowser( this )
            
            if isempty(this.client_)
                this.client_ = this.getClient();
            end
            osr = this.useOSR_ | this.overrideOSR_;
            browser = this.getBrowser(this.client_,this.url_,osr,this.isTransparent_);  
        end

        function removeClient( this )
            % TODO: rethink this
            clients = this.getClients();
            try clients.remove(this.client_); catch; end
        end

        function installClientListeners( this )

            displayHandler = web.DisplayHandler();
            this.client_.addDisplayHandler(displayHandler);

            loadHandler = web.LoadHandler();
            this.client_.addLoadHandler(loadHandler); 

            lifeSpanHandler = web.LifeSpanHandler();
            this.client_.addLifeSpanHandler(lifeSpanHandler);
            
            jsDialogHandler = web.JSDialogHandler();
            this.client_.addJSDialogHandler(jsDialogHandler);
            
            downloadHandler = web.DownloadHandler();
            this.client_.addDownloadHandler(downloadHandler);

            this.setContextMenuHandler();

            this.clientListeners_ = [...
                addlistener(displayHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(loadHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(lifeSpanHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(jsDialogHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(downloadHandler.getCallback,'delayed',@this.onClientAction)];           
        end

        function setContextMenuHandler( this )

            contextMenuHandler = web.ContextMenuHandler(this.isContextMenuEnabled_);
            this.client_.removeContextMenuHandler();
            this.client_.addContextMenuHandler(contextMenuHandler); 
            this.contextMenuHandlerListener_ = addlistener(contextMenuHandler.getCallback,'delayed',@this.onClientAction); 
        end        

        function installHandleListener( this, handle, browser )

            fig = ancestor(handle,'figure');
            handleListener = addlistener(fig,'ObjectBeingDestroyed',...
                @(s,e,b) this.onParentDestroyed(s,e,browser));
            if isempty(this.handleListeners_)
                this.handleListeners_ = handleListener;
            else
                this.handleListeners_ = [this.handleListeners_,handleListener];
            end
        end

        function onParentDestroyed( ~, ~, ~, browser )
            
            try
                browser.getUIComponent.removeNotify();
                browser.setCloseAllowed();
                browser.close(true);
            catch
            end
        end

        function onBrowserPanelAction( ~, src, evnt )

            if (evnt.getID == javax.swing.event.AncestorEvent.ANCESTOR_REMOVED)
                if isa(evnt.getAncestorParent,...
                        'com.jidesoft.swing.JideTabbedPane'); return;end
                try
                    browser = src.getClientProperty('CEFBrowser');
                    browser.close(true);
                    delete(src);                    
                catch
                end
            end
        end

        function onClientAction( this, ~, evnt )

            if ~this.hasFirstBrowserBeenCreated_; return; end

            browser = evnt.Browser;

            switch evnt.Type.getCode
                case web.EventType.LOAD_ERROR.getCode  
                    if ~evnt.IsMainFrame; return; end
                    if ~isequal(evnt.ErrorCode.getCode,web.ErrorCode.ERR_NONE.getCode) &&...
                       ~isequal(evnt.ErrorCode.getCode,web.ErrorCode.ERR_ABORTED.getCode)
                        this.errorCode_ = evnt.ErrorCode;
                        this.errorMsg_ = this.createErrorMessage(...
                            this.errorCode_,evnt.ErrorText,evnt.URL);
                        browser.stopLoad();
                    end
                case web.EventType.ADDRESS_CHANGE.getCode
                    if ~strcmp(this.url_,char(evnt.URL)) && evnt.IsMainFrame
                        this.url_ = char(evnt.URL);
                        notify(this,'AddressChanged');
                    end
                case web.EventType.TITLE_CHANGE.getCode
                    if ~strcmp(this.title_,char(evnt.Title))
                        this.title_ = char(evnt.Title);
                        notify(this,'TitleChanged');
                    end
                case web.EventType.STATUS_MESSAGE.getCode
                    this.statusMessage_ = char(evnt.StatusMessage);
                    notify(this,'StatusMessageUpdated');
                case web.EventType.CONSOLE_MESSAGE.getCode
                         
                case web.EventType.TOOLTIP.getCode
                    
                case web.EventType.CURSOR_CHANGE.getCode
                    
                case web.EventType.LOADING_STATE_CHANGE.getCode
                    this.isLoading_ = evnt.IsLoading;
                    notify(this,'LoadingStateUpdated');                   
                    if ~this.isLoading_ && ~isempty(this.errorMsg_)
                        dataURI = this.createDataURI('text/html',this.errorMsg_);
                        browser.loadURL(dataURI);
                        this.removeFromHistory(browser,dataURI);
                        this.errorMsg_ = '';
                        return
                    end 
                    if ~this.isLoading_ && isempty(this.errorMsg_)
                        if evnt.CanGoBack ~= this.canGoBack_
                            this.canGoBack_ = evnt.CanGoBack;
                            notify(this,'CanGoBackUpdated')
                        end
                        if evnt.CanGoForward ~= this.canGoForward_
                            this.canGoForward_ = evnt.CanGoForward;
                            notify(this,'CanGoForwardUpdated')
                        end
                        if this.retrieveFavicon_
                            icon = this.fetchFavicon(this.favIconMap_,...
                                this.getDomain(browser.getURL)); 
                            if icon ~= this.favicon_
                                this.favicon_ = icon;
                                notify(this,'IconChanged');
                            end
                        end
                    end
                case web.EventType.LOAD_START.getCode

                case web.EventType.LOAD_END.getCode
                   
                case web.EventType.BEFORE_POPUP.getCode
                    
                case web.EventType.AFTER_CREATED.getCode      
                    this.focusedBrowserID_ = browser.getIdentifier;
                    this.focusedBrowser_ = browser;                    
                case web.EventType.AFTER_PARENT_CHANGED.getCode
                    
                case web.EventType.ON_DIALOG.getCode

                case web.EventType.IMAGE_DOWNLOAD.getCode
                    this.showImageInTool(evnt.URL,evnt.Title)
                case web.EventType.SOURCE_DOWNLOAD.getCode  
                    matlab.desktop.editor.newDocument(evnt.SourceText.char);
            end

            if this.showDebug_
                if isempty(browser); browser = this.focusedBrowser_; end
                this.printDebugMessage(browser,evnt);
            end
        end

        function onImageDownload( ~, ~, evnt )

            url = evnt.URL.toString.char;

            if contains(url,'webp'); return; end
            
            showImage = true;
            
            if startsWith(url,'data')                
                s = split(url,',');
                strData = s{2};
                data = java.util.Base64.getDecoder.decode(strData);
                bais = java.io.ByteArrayInputStream(data);
                bi = javax.imageio.ImageIO.read(bais);
                w = bi.getWidth();
                h = bi.getHeight;
                pixelsData = reshape(typecast(bi.getData.getDataStorage, 'uint8'), 3, w, h);
                I = cat(3, ...
                    transpose(reshape(pixelsData(3, :, :), w, h)), ...
                    transpose(reshape(pixelsData(2, :, :), w, h)), ...
                    transpose(reshape(pixelsData(1, :, :), w, h)));  
            else
                try I = imread(url); catch; showImage = false;  end                    
            end
            
            if showImage
                try imtool(I); catch; imshow(I); end
            end
        end
      
    end

    methods(Access = protected, Static = true)

        function domain = getDomain( URL )
            
            domain = [];

            if contains(URL.toString.char,'data'); return; end

            try
                if isa(URL,'com.mathworks.html.Url')
                    URL = java.net.URL(URL.toString);
                else
                    URL = com.mathworks.html.Url.parseSilently(URL);  
                    if isempty(URL); return; end
                    URL = java.net.URL(URL.toString);
                end
                URI = java.net.URI(URL.toString);
                domain = URI.getHost();
                %if domain.startsWith('www.')
                    %domain = domain.substring(4);
                %end
            catch
            end
        end

        function  icon = fetchFavicon( map, domain )
            
            icon = Browser.GENERIC_ICON;
            if isempty(domain); return; end
            if map.containsKey(domain)

                icon = map.get(domain);
            else                
                strQuery = java.lang.StringBuilder(...
                    'https://www.google.com/s2/favicons?domain=');
                strQuery.append(domain);
                strQuery.append('&sz=16');
                try
                    URL = java.net.URL(strQuery.toString);
                    image = java.awt.Toolkit.getDefaultToolkit().createImage(URL.getContent);
                    icon = javax.swing.ImageIcon(image);
                    map.put(domain,icon);
                catch
                end
            end
        end
        
        function cefClient = getClient()

            cefClient = org.cef.CefApp.getInstance().createClient();
        end

        function cefClients = getClients()

            cefClients = Browser.getFieldValueByName(org.cef.CefApp.getInstance(),'clients_');
        end

        function cefBrowser = getBrowser( cefClient, url, isOffScreenRendered, isTransparent )

            cefBrowser = cefClient.createBrowser(url,isOffScreenRendered,isTransparent,[]);
        end

        function cefBrowsers = getBrowsers( cefClient )

            cefBrowsers = Browser.getFieldValueByName(cefClient,'browser_');
        end        

        function setDebugPort( port )
            % Doesn't work
            if nargin == 0
                port = 2012;
            end
            com.mathworks.toolbox.matlab.jcefapp.JcefClient.getInstance.setDebugPort(int32(port));
        end

        function str = formateErrorCode( errorCode )

            str = [errorCode.toString.char,'(', num2str(errorCode.getCode),')'];
        end

        function msg = createErrorMessage( errorCode, errorText, failedUrl )

            msg = '<html><head><title>Error while loading</title></head><body>';
            try
                msg = [msg,'<center><h1 style="text-align:center">',errorCode.toString.char,'</h1></center>'];
            catch
                msg = [msg,'<h1 style="text-align:center">UNKOWN_ERROR</h1>'];
            end
            msg = [msg,'<hr><center>ucdn/1.22.1</center>'];
            msg = [msg,'<h4>Failed to load : <br>', char(failedUrl),'</h4>'];
            if ~isempty(errorText)
                msg = [msg,'<p>',char(errorText),'</p>'];
            end
            msg = [msg,'</body></html>'];

        end

        function printDebugMessage( browser, evnt )
            
            typecode = evnt.Type.getCode;
            msg = ['Browser(', int2str(browser.getIdentifier), '): ',...
                evnt.Type.toString.char, ' %s\n'];
            if isequal(typecode,web.EventType.STATUS_MESSAGE.getCode)
                msg = sprintf(msg,char(evnt.StatusMessage));
            elseif isequal(typecode,web.EventType.CONSOLE_MESSAGE.getCode)
                msg = sprintf(msg,char(evnt.ConsoleMessage));
            elseif isequal(typecode,web.EventType.LOADING_STATE_CHANGE.getCode)  
                state = ['(',upper(java.lang.Boolean(evnt.IsLoading).toString.char),', ',...
                             upper(java.lang.Boolean(evnt.CanGoBack).toString.char),', ',...
                             upper(java.lang.Boolean(evnt.CanGoForward).toString.char),')'];
                msg = sprintf(msg,state);
            elseif isequal(typecode,web.EventType.LOAD_START.getCode) ||...
                    isequal(typecode,web.EventType.LOAD_END.getCode) 
                try
                    frameName = [' : Frame name : ',evnt.FrameName.toString.char];
                catch
                    frameName = '';
                end
                msg = sprintf(msg,frameName);
            elseif isequal(typecode,web.EventType.TITLE_CHANGE.getCode)
                msg = sprintf(msg,evnt.Title.toString.char);
            else
                msg = sprintf(msg,' ');
            end
            warning('off')
            fprintf(msg)
            warning('on')
        end
    end

    methods(Access = public, Static = true)

        function browser = getCanvasBrowser( hparent )
            browser = Browser(Browser.BLANK_URL,hparent,'EnableContextMenu',false);
        end

    end

    methods(Access = public, Static = true, Hidden = true)

        function removeFromHistory( browser, URL )
            try
                js = sprintf('document.location.replace(%s%s%s)',char(34),URL,char(34));
                browser.executeJavaScript(js,'', 1);
            catch
            end
        end

        function [ URL, type ] = validateURL( URL )              

            if isempty(URL)
                URL = Browser.DEFAULT_URL;
                type = 'WEB';
                return
            end   

            if startsWith(URL,'data'); type = 'DATA'; return; end 

            try
                URL = com.mathworks.html.Url.parse(URL);               
                type = URL.getType.toString.char;  
                URL = URL.toString.char;
            catch 
                URL = ['google.com/search?q=',URL];
                try
                    URL = com.mathworks.html.Url.parse(URL);
                    type = URL.getType.toString.char;  
                    URL = URL.toString.char;
                catch
                    error('Null or malformed URL')
                end
            end
        end

        function panel = createJavaWrapperPanel( hparent, jcomponent, position )

            panel = hgjavacomponent(...
                        'Parent',hparent,...
                        'JavaPeer',jcomponent,...
                        'Units','normalized',...
                        'Position',position,...
                        'HitTest','off'); 
        end

        function container = createFlowContainer( parent, flowdirection )

            container = uiflowcontainer('v0',...
                'Parent',parent,...
                'Units','norm',...
                'Position',[0,0,1,1],...
                'Margin',1,...
                'FlowDirection',flowdirection);            
        end

        function panel = createPanel( parent, heightlimits, widthlimits )

            panel = uipanel(...
                'Parent',parent,...
                'BorderType','none',...
                'Units','norm',...
                'Position',[0,0,1,1]);
            
            if nargin == 1; return; end
            
            if ~isempty(heightlimits)                
                try panel.HeightLimits = heightlimits; catch; end
            end
            if ~isempty(widthlimits)                
                try panel.WidthLimits = widthlimits; catch; end
            end            
        end  

        function container = createGridContainer( parent, gridsize )
            %matlab.ui.container.internal.UIGridContainer
            container = uigridcontainer('v0',...
                'Parent', parent  ,...
                'GridSize',gridsize,...
                'BackgroundColor','w',...
                'Units','norm',...
                'Position',[0,0,1,1],...
                'Margin',1);  
        end        

        function [icon, domain] = getFavicon( URL )
        
            %icon = [];
            domain = [];
        
            if isa(URL,'com.mathworks.html.Url')
                URL = java.net.URL(URL.toString);
            else
                URL = com.mathworks.html.Url.parseSilently(URL); %#ok<*JAPIMATHWORKS> 
                if isempty(URL); return; end
                URL = java.net.URL(URL.toString);
            end
            domain = URL.getHost;
            strQuery = ['https://www.google.com/s2/favicons?domain=',URL.getHost.char,'&sz=16'];
            try
                URL = java.net.URL(strQuery);
                image = java.awt.Toolkit.getDefaultToolkit().createImage(URL.getContent);
                icon = javax.swing.ImageIcon(image);
            catch
                Browser.GENERIC_ICON;
            end
        end        

        function dataURI = createDataURI( mimeType, contents)

            jcontents = java.lang.String(contents);
            byteStr = java.util.Base64.getEncoder().encodeToString(jcontents.getBytes()).char;
            dataURI = ['data:',mimeType,';base64,',byteStr];
        end

        function showImageInTool( url, suggestedName ) %#ok<INUSD> 
            
            if isjava(url); url = url.toString.char; end

            if contains(url,'webp'); return; end
            
            showImage = true;
            
            if startsWith(url,'data')                
                s = split(url,',');
                strData = s{2};
                data = java.util.Base64.getDecoder.decode(strData);
                bais = java.io.ByteArrayInputStream(data);
                bi = javax.imageio.ImageIO.read(bais);
                w = bi.getWidth();
                h = bi.getHeight;
                pixelsData = reshape(typecast(bi.getData.getDataStorage, 'uint8'), 3, w, h);
                I = cat(3, ...
                    transpose(reshape(pixelsData(3, :, :), w, h)), ...
                    transpose(reshape(pixelsData(2, :, :), w, h)), ...
                    transpose(reshape(pixelsData(1, :, :), w, h)));  
            else
                try I = imread(url); catch; showImage = false;  end                    
            end
            
            if showImage
                try imtool(I); catch; imshow(I); end
            end
        end        

        function settings = getSettings()

            cefApp = org.cef.CefApp.getInstance();
            s = Browser.getFieldValueByName(cefApp,'settings_');
            % TODO: someting wrong converting color->java color->matlab
            % color
            bgcolor = java.awt.Color(s.background_color.getColor);
            color = [bgcolor.getRed,bgcolor.getGreen,bgcolor.getBlue,bgcolor.getAlpha]./255;
            settings = struct(...
                'browser_subprocess_path',char(s.browser_subprocess_path),...
                'framework_dir_path', char(s.framework_dir_path),...
                'windowless_rendering_enabled',s.windowless_rendering_enabled,...
                'command_line_args_disabled', s.command_line_args_disabled,...
                'cache_path', char(s.cache_path),...
                'persist_session_cookies', s.persist_session_cookies,...
                'user_agent', char(s.user_agent),...
                'product_version', char(s.product_version),...
                'locale',char(s.locale),...
                'log_file', char(s.log_file),...
                'log_severity',char(s.log_severity.toString),...
                'javascript_flags',char(s.javascript_flags),...
                'resources_dir_path',char(s.resources_dir_path),...
                'locales_dir_path',char(s.locales_dir_path),...
                'pack_loading_disabled',s.pack_loading_disabled,...
                'remote_debugging_port', s.remote_debugging_port,...
                'uncaught_exception_stack_size',s.uncaught_exception_stack_size,...
                'ignore_certificate_errors',s.ignore_certificate_errors,...
                'background_color',color);
        end

        function obj = getFieldValueByName( baseObj, fieldname )

            obj = [];
            field = [];
            clazz = baseObj.getClass;
            while isempty(field)
                try
                    field = clazz.getDeclaredField(fieldname);
                    isAccessible = field.isAccessible;
                    if ~isAccessible
                        field.setAccessible(true);
                    end
                    obj = field.get(baseObj);
                    field.setAccessible(isAccessible);
                catch 
                    clazz = clazz.getSuperclass;
                    if isempty(clazz); return; end
                    baseObj = clazz.cast(baseObj);                    
                end
            end
        end

        function setFieldValueByName( baseObj, fieldname, value )

            field = [];
            clazz = baseObj.getClass;
            while isempty(field)
                try
                    field = clazz.getDeclaredField(fieldname);
                    isAccessible = field.isAccessible;
                    if ~isAccessible
                        field.setAccessible(true);
                    end
                    field.set(baseObj,value);
                    field.setAccessible(isAccessible);
                catch 
                    clazz = clazz.getSuperclass;
                    if isempty(clazz); return; end
                    baseObj = clazz.cast(baseObj);                    
                end
            end
        end 
    end
end