package web;

import org.cef.browser.CefBrowser;
import org.cef.browser.CefFrame;
import org.cef.callback.CefContextMenuParams;
import org.cef.callback.CefMenuModel;
import org.cef.callback.CefMenuModel.MenuId;
import org.cef.handler.CefContextMenuHandler;
import org.cef.callback.CefStringVisitor;
import com.mathworks.jmi.Callback;

//import javax.swing.JComponent;


public class ContextMenuHandler implements CefContextMenuHandler {

    private final Callback source_callback = new Callback();
    private final PageVisitor visitor = new PageVisitor(this.source_callback);
    private final boolean is_enabled_;
    
    public ContextMenuHandler( boolean isenabled) {
        this.is_enabled_ = isenabled;
    }

    @Override
    public void onBeforeContextMenu(CefBrowser browser,
                                    CefFrame frame,
                                    CefContextMenuParams params,
                                    CefMenuModel model) {
        model.clear();
        
        if (this.is_enabled_){

            // Navigation menu
            model.addItem(MenuId.MENU_ID_BACK, "Back");
            model.setEnabled(MenuId.MENU_ID_BACK, browser.canGoBack());

            model.addItem(MenuId.MENU_ID_FORWARD, "Forward");
            model.setEnabled(MenuId.MENU_ID_FORWARD, browser.canGoForward());

            model.addSeparator();
            model.addItem(MenuId.MENU_ID_FIND, "Find...");
        
            String URL = params.getSourceUrl();  
            if (params.hasImageContents() && URL != null){
                String displayStr = (URL.contains("webp"))?"Download image...":"Open image in imtool...";
                model.addItem(MenuId.MENU_ID_USER_FIRST,displayStr );
            }
            model.addItem(MenuId.MENU_ID_VIEW_SOURCE, "View source in Editor...");
        }
    }

    @Override
    public boolean onContextMenuCommand(CefBrowser browser, CefFrame frame,
            CefContextMenuParams params, int commandId, int eventFlags) {
        switch (commandId) {
            case MenuId.MENU_ID_VIEW_SOURCE:
                browser.getSource(this.visitor);
                return true;
            case MenuId.MENU_ID_USER_FIRST:
                browser.startDownload(params.getSourceUrl());
                return true;
            /*case MenuId.MENU_ID_USER_LAST:
                JComponent split_pane = (JComponent) browser.getUIComponent().getParent().getParent();
                split_pane.add(browser.getDevTools().getUIComponent());
                split_pane.revalidate();
                split_pane.repaint();*/
            default:
                return false;
        }
    }

    @Override
    public void onContextMenuDismissed(CefBrowser browser, CefFrame frame) {

    }
    
    public Callback getCallback(){
        
        return this.source_callback;
    }    
}
    
    class PageVisitor implements CefStringVisitor{
        
        private final Callback callback;
        
        public PageVisitor( Callback callback) {
            
            this.callback = callback;
        }   
 
         @Override
        public void visit(String string) {
            this.callback.postCallback(new BrowserEventData( string ));
        }
    }


