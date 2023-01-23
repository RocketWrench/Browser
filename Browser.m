classdef Browser < handle

    properties(Access = public, Dependent = true, SetObservable, AbortSet)

        URL
        Title
        Favicon
        IsLoading
        CanGoBack
        CanGoForward
        ErrorCode
        StatusMessage        
    end

    properties(Access = public, Dependent = true)

        BrowserID
        RetriveFavicon
        EnableContextMenu
        EnableAddressPane
        ShowDebug
    end

    properties(Access = protected)

        client_;
        clientListeners_;

        browsers_ = java.util.HashMap;
        freeBrowserIDs(:,1) int32;
        focusedBrowserID_;
        focusedBrowser_;

        devTools_;

        maxFreeBrowsers_(1,1) uint8 = 2;

        url_(1,:) char = Browser.DEFAULT_URL;
        favicon_ = [];
        favIconMap_;

        title_(1,:) char  = '';
        statusMessage_(1,:) char = '';

        errorCode_(1,:) char = '';
        errorMsg_(1,:) char  = '';

        handleListeners_
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
        debug_(1,1) logical = false;
    end

    properties(Access = protected, Constant = true)

        DEFAULT_URL = 'https://www.google.com/';
        DEFAULT_POSITION = [0,0,1,1];
        BLANK_URL = 'about:blank';
        NO_ERROR = 'ERROR_NONE(0)';
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
        function this = Browser( URL, parent, position )

            narginchk(0,4)                      

            if nargin
                this.url_ = this.validateURL(URL);
                this.initialize();

                if nargin > 1
                    pos = this.DEFAULT_POSITION;
                    if nargin > 2
                        pos = position;
                    end
                    this.install(parent,pos);
                end                
            end           
        end

        function delete( this )

            try delete(this.clientListeners_); catch; end
            try delete(this.handleListeners_); catch; end
            try this.client_.dispose(); catch; end 
            %this.removeClient()           
          end

    end

    methods(Access = public)

        function varargout = install( this, hparent, position )
            % install browser panel in a hg parent            

            narginchk(1,3)
            nargoutchk(0,3); 

            drawnow();
            
            browser = this.focusedBrowser_;

            if this.enableAddressPane_
                browserPanel = this.getPanelWithAddressPane(browser);                
            else
                browserPanel = handle(browser.getUIComponent(),'CallbackProperties'); 
                browserPanel.AncestorRemovedCallback = @this.onBrowserPanelAction; 
            end
            
            browserPanel.setName(num2str(browser.getIdentifier));
            browserPanel.putClientProperty('CEFBrowser',browser);
                         

            if nargin > 1
                if ~isvalid(hparent)
                    error('webBrowser:InvalidParent', 'hparent must be a valid graphics handle')
                end

                if nargin < 3
                    pos = this.DEFAULT_POSITION;
                else
                    pos = position;
                end               
                
                container = this.createJavaWrapperPanel(hparent,browserPanel,pos);
                drawnow() 
                this.installHandleListener(hparent,browser);
            end   

           container = [];

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

        function addNew( this, URL )

            if nargin > 1
                this.url_ = this.validateURL(URL);
            end
            osr = this.useOSR_ | this.overrideOSR_;
            this.focusedBrowser_ = this.getBrowser(this.client_,this.url_,...
                osr,this.isTransparent_);
            this.focusedBrowserID_ = this.focusedBrowser_.getIdentifier();
            drawnow();
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

            loadDirectly = false;

            switch nargin
                case 2
                    browser = this.focusedBrowser_;
                    if numel(strContent) > 5
                        loadDirectly = strcmp(strContent(1:5),'data:');
                    end
                    mimeType = 'text/html';                    
                case 3
                    loadDirectly = isempty(mimeType);
                    browser = this.focusedBrowser_;
                case 4
                    loadDirectly = isempty(mimeType);
            end
            browser.stopLoad();
            if loadDirectly
                browser.loadURL(strContent);
            else
                browser.loadURL(this.createDataURI(mimeType,char(strContent)));
            end

            drawnow();
        end

        function alert( this, msg )
            
            code = ['alert(''',msg,''');'];
            this.executeJavaScript(code,this.url_,1);
        end

        function prompt( this, promptstr, defaultval )
            code = ['var value = prompt(''',promptstr,''', ''',defaultval,''');'];
            this.executeJavaScript(code,this.url_,1);
        end

        function executeJavaScript( this, code, url, lineno )

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

        end

        function setMaxFreeBrowsers( this, n )
            % TODDO: input checking
            this.maxFreeBrowsers_ = n;
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
            %val = this.focusedBrowserID_;
            val = this.focusedBrowser_.getIdentifier();
        end

        function val = get.Favicon( this )
            %if ~isempty(this.favicon_)
                val = this.favicon_;
            %end
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
            if ~(this.isContextMenuEnabled_ & val) %#ok<AND2> 
                this.isContextMenuEnabled_ = val;
                this.setContextMenuHandler();
            end
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
            val = this.debug_;
        end

        function set.ShowDebug( this, val )
            this.debug_ = logical(val);
        end
    end

    methods(Access = public, Hidden = true)

        function browsers = getAllBrowsers( this )
            browsers = this.getFieldValueByName(this.client_,'browser_');
            try browsers = browsers.values().toArray(); catch; end
        end
    end

    methods(Access = protected)

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

            osr = this.useOSR_ | this.overrideOSR_;
            browser = this.getBrowser(this.client_,this.url_,osr,this.isTransparent_);  
            browser.createImmediately();
        end

        function removeClient( this )
            % TODO: rethink this
            clients = this.getClients();
            try clients.remove(this.client_); catch; end
        end
    end

    methods(Access = protected)

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

            contextMenuHandler = web.ContextMenuHandler();
            this.client_.removeContextMenuHandler();
            this.client_.addContextMenuHandler(contextMenuHandler);

            this.clientListeners_ = [...
                addlistener(displayHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(loadHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(lifeSpanHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(jsDialogHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(downloadHandler.getCallback,'delayed',@this.onClientAction);...
                addlistener(contextMenuHandler.getCallback,'delayed',@this.onClientAction)];           
        end

        function setContextMenuHandler( this )

            if this.isContextMenuEnabled_
                contextMenuHandler = web.ContextMenuHandler();                
                this.client_.addContextMenuHandler(contextMenuHandler);
            end
        end        

        function installHandleListener( this, handle, browser )

            fig = ancestor(handle,'figure');
            handleListener = addlistener(fig,'ObjectBeingDestroyed',@(s,e,b) this.onParentDestroyed(s,e,browser));
            if isempty(this.handleListeners_)
                this.handleListeners_ = handleListener;
            else
                this.handleListeners_ = [this.handleListeners_,handleListener];
            end
        end

        function onParentDestroyed( this, src, evnt, browser )
            
            try
                browser.getUIComponent.removeNotify();
                browser.setCloseAllowed();
                browser.close(true);
            catch
            end
        end

        function onBrowserPanelAction( this, src, evnt )

            if evnt.getID == javax.swing.event.AncestorEvent.ANCESTOR_REMOVED
                try
                        browser = src.getClientProperty('CEFBrowser');
                        browser.close(true);
                        
                        if ~src.isValid
                            try this.freeBrowserIDs(end+1) = int32(str2double(src.getName.char)); catch; end
                        end
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
                                this.getDomain(browser.getURL),this.GENERIC_ICON); 
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

            if this.debug_
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

        function browserPanel = getPanelWithAddressPane( this, browser )
            import com.jidesoft.swing.JideBoxLayout 
            import javax.swing.BorderFactory

            panel = handle(browser.getUIComponent,'CallbackProperties');
            panel.AncestorRemovedCallback = @this.onBrowserPanelAction; 

            iconpath = [fullfile(fileparts(mfilename('fullpath')),'icons'),filesep];
            border = BorderFactory.createLineBorder(java.awt.Color.WHITE,4,true);

            cls = 'javax.swing.JPanel';
            browserPanel = javaObjectEDT(cls,java.awt.BorderLayout);
            browserPanel.putClientProperty('SPLIT_PANE_CLIENT',java.lang.Boolean.TRUE);

            addressPane = javaObjectEDT(cls);
            addressPane.setBackground(java.awt.Color.WHITE);
            cls = 'com.jidesoft.swing.JideBoxLayout';
            layout = javaObjectEDT(cls,addressPane,JideBoxLayout.X_AXIS,2);
            addressPane.setLayout(layout);
            addressPane.setBorder(com.jidesoft.swing.PartialLineBorder(java.awt.Color(0.9,0.9,0.9,0.6),2,com.jidesoft.swing.PartialSide.SOUTH));
            addressPane.setPreferredSize(java.awt.Dimension(200,36));
        
            %icon = com.mathworks.common.icons.IconEnumerationUtils.getIcon('arrow_move_left_lg.gif');
            icon = javax.swing.ImageIcon([iconpath,'left.png']);
            backButton = handle(javaObjectEDT('javax.swing.JButton',icon),'CallbackProperties');
            backButton.setEnabled(false);
            backButton.setFocusable(false);
            backButton.setBorder(border);
            backButton.ActionPerformedCallback = @(~,~) browser.goBack;
        
            %icon = com.mathworks.common.icons.IconEnumerationUtils.getIcon('arrow_move_right_lg.gif');
            icon = javax.swing.ImageIcon([iconpath,'right.png']);
            forwardButton = handle(javaObjectEDT('javax.swing.JButton',icon),'CallbackProperties');
            forwardButton.setEnabled(false);
            forwardButton.setFocusable(false);
            forwardButton.setBorder(border);
            forwardButton.ActionPerformedCallback = @(~,~) browser.goForward;
        
            %icon = com.mathworks.common.icons.IconEnumerationUtils.getIcon('refresh.gif');
            icon = javax.swing.ImageIcon([iconpath,'refresh.png']);
            reloadButton = handle(javaObjectEDT('javax.swing.JButton',icon),'CallbackProperties');
            reloadButton.setFocusable(false);
            reloadButton.setBorder(border);
            reloadButton.ActionPerformedCallback = @(~,~) browser.reloadIgnoreCache;
        
            %icon = com.mathworks.common.icons.IconEnumerationUtils.getIcon('home.gif');
            icon = javax.swing.ImageIcon([iconpath,'home.png']);
            homeButton = handle(javaObjectEDT('javax.swing.JButton',icon),'CallbackProperties');
            homeButton.setFocusable(false);
            homeButton.setBorder(border);
            homeButton.ActionPerformedCallback = @(~,~) browser.loadURL(this.DEFAULT_URL);            
            
            addressField = handle(javaObjectEDT('javax.swing.JTextField',browser.getURL),'CallbackProperties');
            addressField.setBorder(BorderFactory.createCompoundBorder(border,BorderFactory.createEmptyBorder(0,4,0,0)));
            addressField.setBackground(java.awt.Color(0.9,0.9,0.9,0.6))  
            addressField.ActionPerformedCallback = @(~,~) browser.loadURL(getAddress);
            addressField.MouseClickedCallback = @(~,~) onMouseClicked;
        
            addressPane.add(backButton,JideBoxLayout.FIX);
            addressPane.add(forwardButton,JideBoxLayout.FIX);
            addressPane.add(reloadButton,JideBoxLayout.FIX);
            addressPane.add(homeButton,JideBoxLayout.FIX);
            addressPane.add(addressField,JideBoxLayout.VARY);
            
            browserPanel.add(addressPane,'North');
            browserPanel.add(panel,'Center');

            addlistener(this,'AddressChanged',@(s,e) onAddressChange(s,e));
            addlistener(this,'CanGoBackUpdated',@(s,e) onCanGoBack(s,e));
            addlistener(this,'CanGoForwardUpdated',@(s,e) onCanGoForward(s,e)); 

            browserPanel = handle(browserPanel,'CallbackProperties');

            function onMouseClicked( src, evnt ) %#ok<INUSD> 
                java.awt.KeyboardFocusManager.getCurrentKeyboardFocusManager.clearGlobalFocusOwner;
                addressField.requestFocus();
            end

            function onAddressChange( src, evnt )                %#ok<INUSD> 
                try addressField.setText(browser.getURL);catch;end
            end
        
            function onCanGoBack( src, evnt )        %#ok<INUSD> 
                backButton.setEnabled(browser.canGoBack);
            end
        
            function onCanGoForward( src, evnt )        %#ok<INUSD> 
                forwardButton.setEnabled(browser.canGoForward);
            end  

            function URL = getAddress()
                URL = addressField.getText().toString.char;
                URL = this.validateURL(URL);
%                 try
%                     str = str.replaceAll(' ','%20');
%                     URI = java.net.URI(str);
%                     if ~isempty(URI.getScheme); return; end
%                     if ~isempty(URI.getHost) && ~isempty(URI.getPath); return; end
%                     part = URI.getSchemeSpecificPart();
%                     if (part.indexOf('.') == -1)
%                         str = java.lang.String(['google.com/search?q=',str.char]);
%                     end
%                 catch
%                     str = java.lang.String(['google.com/search?q=',str.char]);
%                 end
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
    
                domain = URL.getHost; 
            catch
            end
        end

        function  icon = fetchFavicon( map, domain, generic )
            
            icon = generic;
            if isempty(domain); return; end
            if map.containsKey(domain)

                icon = map.get(domain);
            else                
                strQuery = java.lang.StringBuilder('https://www.google.com/s2/favicons?domain=');
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

%         function URL = parseURL( URL )
%             try
%                 if ischar(URL) || istring(URL)
%                     URL = com.mathworks.html.UrlBuilder.fromString(char(URL)).toString.char;
%                 elseif isa(URL,'java.io.File')
%                     URL = com.mathworks.html.UrlBuilder.fromFile(URL).toString.char;
%                 elseif isa(URL,'java.net.URL')
%                     URL = com.mathworks.html.UrlBuilder.fromURL(URL).toString.char;
%                 else
%                     URL = ['google.com/search?q=',URL];
%                 end
%             catch
%                 URL = ['google.com/search?q=',URL];
%             end
%         end
        
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

    methods(Access = public, Static = true, Hidden = true)

        function removeFromHistory( browser, URL )
            try
                js = sprintf('document.location.replace(%s%s%s)',char(34),URL,char(34));
                browser.executeJavaScript(js,'', 1);
            catch
            end
        end

        function [ URL, type ] = validateURL( URL )            

            if isempty(URL); URL = 'https://www.google.com/'; end

            if startsWith(URL,'data'); type = 'DATA'; return; end           

            try
                URL = com.mathworks.html.Url.parse(URL);               
                type = URL.getType.toString.char;  
                URL = URL.toString.char;
            catch ME
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

        function [icon, domain] = getFavicon( URL )
        
            %icon = [];
            domain = [];
        
            if isa(URL,'com.mathworks.html.Url')
                URL = java.net.URL(URL.toString);
            else
                URL = com.mathworks.html.Url.parseSilently(URL);
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
                icon = com.mathworks.common.icons.IconEnumerationUtils.getIcon('web_globe.png');
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