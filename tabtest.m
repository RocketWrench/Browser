function b = tabtest

    URL = 'google.com';

    b = web.Browser();
    b.RetriveFavicon = true;
    b.EnableContextMenu = true;
    b.EnableAddressPane = true;
    b.setMaxFreeBrowsers(15);
    
    addlistener(b,'IconChanged',@(s,e) onIconChange(s,e));
    addlistener(b,'TitleChanged',@(s,e) onTitleChange(s,e));

    tabPane = creatabbedPane();
    
    %icon = com.mathworks.common.icons.IconEnumerationUtils.getIcon('new_ts_16.png');
    addTabBut = handle(javaObjectEDT('javax.swing.JButton','Add Tab'),'CallbackProperties');
    %addTabBut.setBorder(javax.swing.BorderFactory.createEmptyBorder);
    addTabBut.ActionPerformedCallback = @(s,e) addNewTab(s,e);

    tabPane.setTabTrailingComponent(addTabBut);
    tabPane.addTab('',javax.swing.JPanel); 

    f = figure();
    b.createJavaWrapperPanel(f,tabPane,[0,0,1,1]); 
    drawnow()
    
    tabPane.setComponentAt(0,b.install(URL))
    tabPane.setTitleAt(0,b.Title);
    tabPane.setIconAt(0,b.Favicon);
 

    function addNewTab( src, evnt )

        tabPane.addTab('',javax.swing.JPanel); 
        index = tabPane.getTabCount - 1;
        tabPane.setComponentAt(index,b.install(URL))
        tabPane.setTitleAt(index,b.Title);
        tabPane.setIconAt(index,b.Favicon);        
        tabPane.setSelectedIndex(index);
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
