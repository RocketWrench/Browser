function b = TabbedBrowserDemo( dodebug )
    
    if ~nargin; dodebug = false; end

    URL = 'google.com';

    b = Browser(URL);
    b.RetriveFavicon = true;
    b.EnableContextMenu = true;
    b.EnableAddressPane = true;
    b.ShowDebug = dodebug;
    
    addlistener(b,'IconChanged',@(s,e) onIconChange(s,e));
    addlistener(b,'TitleChanged',@(s,e) onTitleChange(s,e));

    tabPane = creatabbedPane();
    tabPane.ComponentRemovedCallback = @(s,e) onTabDeleted(s,e);

    iconpath = [fullfile(fileparts(mfilename('fullpath')),'icons'),filesep];
    icon = javax.swing.ImageIcon([iconpath,'addtab.png']);
    addTabBut = handle(javaObjectEDT('com.jidesoft.swing.NullJideButton',icon),'CallbackProperties');
    addTabBut.setFocusable(false);
    addTabBut.ActionPerformedCallback = @(s,e) addNewTab(s,e);

    tabPane.setTabTrailingComponent(addTabBut);
    tabPane.insertTab(b.Title,b.Favicon,b.install,'',0);

    f = figure();
    b.createJavaWrapperPanel(f,tabPane,[0,0,1,1]); 
    drawnow()

    function addNewTab( src, evnt )
        index = tabPane.getTabCount;
        b.addNew(URL);
        %panel = b.install();
        tabPane.insertTab(b.Title,b.Favicon,b.install,'',index); 
        tabPane.setSelectedIndex(index);
    end

    function onTabDeleted( src, evnt )

    end

    function onIconChange( src, evnt )
        
        try
            tabPane.setIconAt(tabPane.getSelectedIndex,b.Favicon);
        catch
        end
    end

    function onTitleChange( src, evnt )
        
        try
            tabPane.setTitleAt(tabPane.getSelectedIndex,b.Title);
        catch
        end
    end
end

function tabPane = creatabbedPane()
    cls = 'com.jidesoft.swing.JideTabbedPane';
    tabPane = handle(javaObjectEDT(cls),'CallbackProperties');
    %tabPane.setShowCloseButton(true);
    tabPane.setShowCloseButtonOnMouseOver(true);
    tabPane.setShowIconsOnTab(true);
    tabPane.setShowCloseButtonOnTab(true);
    tabPane.setShowTabButtons(false);
    tabPane.setHideOneTab(false);
    tabPane.setLayoutTrailingComponentBeforeButtons(true);
    tabPane.setTabShape(com.jidesoft.swing.JideTabbedPane.SHAPE_ROUNDED_FLAT)
%     tabPane.setColorTheme(com.jidesoft.swing.JideTabbedPane.COLOR_THEME_OFFICE2003);
    tabPane.setTabInsets(java.awt.Insets(4,4,4,4));
    tabPane.setTabResizeMode(com.jidesoft.swing.JideTabbedPane.RESIZE_MODE_DEFAULT);
    tabPane.setTabColorProvider(web.ui.TabColorProvider(tabPane));
end
