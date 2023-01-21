function b = tabtest( dodebug )
    
    if ~nargin; dodebug = false; end

    URL = 'google.com';

    b = Browser();
    b.RetriveFavicon = true;
    b.EnableContextMenu = true;
    b.EnableAddressPane = true;
    b.DisplayDebugMessages = dodebug;
    b.setMaxFreeBrowsers(15);
    
    addlistener(b,'IconChanged',@(s,e) onIconChange(s,e));
    addlistener(b,'TitleChanged',@(s,e) onTitleChange(s,e));

    tabPane = creatabbedPane();

    addTabBut = handle(javaObjectEDT('javax.swing.JButton','Add Tab'),'CallbackProperties');
    addTabBut.ActionPerformedCallback = @(s,e) addNewTab(s,e);

    tabPane.setTabTrailingComponent(addTabBut);

    idx = addDummyTab();

    f = figure();
    b.createJavaWrapperPanel(f,tabPane,[0,0,1,1]); 
    drawnow()
    
    populateTab(idx);

    function index = addDummyTab()
        tabPane.addTab('',javax.swing.JPanel); 
        index = tabPane.getTabCount - 1;
    end

    function populateTab( index )
        tabPane.setComponentAt(index,b.install(URL))
        tabPane.setTitleAt(index,b.Title);
        tabPane.setIconAt(index,b.Favicon);
    end
 

    function addNewTab( src, evnt )
        idx = addDummyTab();
        populateTab(idx);
        tabPane.setSelectedIndex(idx);
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

    tabPane = javaObjectEDT('com.jidesoft.swing.JideTabbedPane');
    %tabPane.setShowCloseButton(true);
    tabPane.setShowCloseButtonOnMouseOver(true);
    tabPane.setShowIconsOnTab(true);
    tabPane.setShowCloseButtonOnTab(true);
    tabPane.setShowTabButtons(false);
    tabPane.setHideOneTab(false);
    tabPane.setLayoutTrailingComponentBeforeButtons(true);
    tabPane.setTabShape(com.jidesoft.swing.JideTabbedPane.SHAPE_ROUNDED_FLAT)
    tabPane.setColorTheme(com.jidesoft.swing.JideTabbedPane.COLOR_THEME_OFFICE2003);
end
