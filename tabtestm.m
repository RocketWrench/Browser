function b = tabtest

    URL = 'google.com';

    f = figure();
    tabgp = uitabgroup(f,'Units','normalized','Position',[0,0,1,1]);

    b = Browser();
    b.RetriveFavicon = true;
    b.EnableContextMenu = true;
    b.EnableAddressPane = true;
    b.setMaxFreeBrowsers(15);
    
    addlistener(b,'IconChanged',@(s,e) onIconChange(s,e));
    addlistener(b,'TitleChanged',@(s,e) onTitleChange(s,e));
    
    b.createJavaWrapperPanel(f,tabPane,[0,0,1,1]); 
    drawnow()

 

    function addNewTab( src, evnt )


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
