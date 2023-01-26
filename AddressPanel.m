classdef AddressPanel < handle

    properties(Access = protected)
        BackButton
        ForwardButton
        RefreshButton
        HomeButton
        BookmanButton
        AddressField
        Pane
        Browser(1,1) Browser
    end

    properties(Access = protected)
        BrowserListeners
    end

    methods(Access = protected)
        function this = AddressPanel( browser )

            if nargin
                this.Browser = browser;
                this.create(browser);
                this.BrowserListeners = [...
                    addlistener(browser,'AddressChanged',@this.onAddressChange),...
                    addlistener(browser,'CanGoBackUpdated',@this.onCanGoBack),...
                    addlistener(browser,'CanGoForwardUpdated',@this.onCanGoForward)]; 
            end
        end
    end

    methods

        function delete( this )
            try delete(this.BrowserListeners); catch; end
            try delete(this.Pane); catch; end
        end
    end

    methods(Access = protected)

        function onBrowserPanelAction( this, ~, evnt )
            if (evnt.getID == javax.swing.event.AncestorEvent.ANCESTOR_REMOVED)
                if isa(evnt.getAncestorParent,...
                        'com.jidesoft.swing.JideTabbedPane'); return;end
                delete(this);
            end
        end

        function onMouseClicked( this, src, evnt ) %#ok<INUSD> 
            java.awt.KeyboardFocusManager.getCurrentKeyboardFocusManager.clearGlobalFocusOwner;
            this.AddressField.requestFocus();
        end

        function onAddressChange( this, ~, ~ )  
            try this.AddressField.setText(this.Browser.URL);catch;end
        end
    
        function onCanGoBack( this, ~, ~ ) 
            this.BackButton.setEnabled(this.Browser.CanGoBack);
        end
    
        function onCanGoForward( this, ~, ~ )
            this.ForwardButton.setEnabled(this.Browser.CanGoForward);
        end  

        function URL = getAddress( this )
            URL = this.AddressField.getText().toString.char;
            URL = this.Browser.validateURL(URL);
        end        

        function create( this, browser )
            import com.jidesoft.swing.JideBoxLayout 
            import javax.swing.BorderFactory

            cefBrowser = browser.getFocusedBrowser();

            panel = handle(cefBrowser.getUIComponent,'CallbackProperties');
            panel.AncestorRemovedCallback = @this.onBrowserPanelAction; 

            iconpath = [fullfile(fileparts(mfilename('fullpath')),'icons'),filesep];
            border = BorderFactory.createLineBorder(java.awt.Color.WHITE,4,true);

            cls = 'javax.swing.JPanel';
            browserPanel = javaObjectEDT(cls,java.awt.BorderLayout);

            addressPane = javaObjectEDT(cls);
            addressPane.setBackground(java.awt.Color.WHITE);
            cls = 'com.jidesoft.swing.JideBoxLayout';
            layout = javaObjectEDT(cls,addressPane,JideBoxLayout.X_AXIS,6);
            addressPane.setLayout(layout);
            addressPane.setBorder(BorderFactory.createCompoundBorder(...                
                com.jidesoft.swing.PartialLineBorder(java.awt.Color(0.9,0.9,0.9,0.6),2,com.jidesoft.swing.PartialSide.SOUTH),...
                BorderFactory.createEmptyBorder(4,4,4,4)));
        
            cls = 'com.jidesoft.swing.NullJideButton';
            icon = javax.swing.ImageIcon([iconpath,'back.png']);
            backButton = handle(javaObjectEDT(cls,icon),'CallbackProperties');
            backButton.setEnabled(false);
            backButton.setFocusable(false);
            backButton.ActionPerformedCallback = @(~,~) browser.goBack;

            icon = javax.swing.ImageIcon([iconpath,'forward.png']);
            forwardButton = handle(javaObjectEDT(cls,icon),'CallbackProperties');
            forwardButton.setEnabled(false);
            forwardButton.setFocusable(false);
            forwardButton.ActionPerformedCallback = @(~,~) browser.goForward;

            icon = javax.swing.ImageIcon([iconpath,'refresh.png']);
            reloadButton = handle(javaObjectEDT(cls,icon),'CallbackProperties');
            reloadButton.setFocusable(false);
            reloadButton.ActionPerformedCallback = @(~,~) cefBrowser.reloadIgnoreCache;

            icon = javax.swing.ImageIcon([iconpath,'home.png']);
            homeButton = handle(javaObjectEDT(cls,icon),'CallbackProperties');
            homeButton.setFocusable(false);
            homeButton.ActionPerformedCallback = @(~,~) browser.loadURL(browser.DEFAULT_URL);

            icon = javax.swing.ImageIcon([iconpath,'bookmark.png']);
            bookmarkButton = handle(javaObjectEDT(cls,icon),'CallbackProperties');
            bookmarkButton.setEnabled(false);
            bookmarkButton.setFocusable(false);            
            
            cls = 'com.jidesoft.swing.LabeledTextField';
            addressField = javaObjectEDT(cls,[],' ');
            addressField.setText(cefBrowser.getURL);
            addressField.setBorder(BorderFactory.createCompoundBorder(border,BorderFactory.createEmptyBorder(0,4,0,0)));
            addressField.setBackground(java.awt.Color(0.9,0.9,0.9,0.6))
            addressField.setPreferredSize(java.awt.Dimension(100,36));
            txtFld = handle(addressField.getTextField(),'CallbackProperties');
            txtFld.ActionPerformedCallback = @(~,~) browser.loadURL(this.getAddress());
            txtFld.MouseClickedCallback = @this.onMouseClicked;
        
            addressPane.add(backButton,JideBoxLayout.FIX);
            addressPane.add(forwardButton,JideBoxLayout.FIX);
            addressPane.add(reloadButton,JideBoxLayout.FIX);
            addressPane.add(homeButton,JideBoxLayout.FIX);
            addressPane.add(addressField,JideBoxLayout.VARY);
            addressPane.add(bookmarkButton,JideBoxLayout.FIX);
            
            browserPanel.add(addressPane,'North');
            browserPanel.add(panel,'Center');

            drawnow();

            this.BackButton = backButton;
            this.ForwardButton = forwardButton;
            this.RefreshButton = reloadButton;
            this.HomeButton = homeButton;
            this.BookmanButton = bookmarkButton;
            this.AddressField = addressField;
            this.Pane = browserPanel;
        end
    end

    methods(Access = public, Static = true)

        function browserPanel = getBrowserPanel( browser )

            addressPane = AddressPanel(browser);
            browserPanel = addressPane.Pane;
        end
    end
end
