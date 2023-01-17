package web;

import org.cef.browser.CefBrowser;
import org.cef.browser.CefFrame;
import org.cef.callback.CefContextMenuParams;
import org.cef.callback.CefMenuModel;
import org.cef.callback.CefMenuModel.MenuId;
import org.cef.handler.CefContextMenuHandler;
import org.cef.callback.CefStringVisitor;
import com.mathworks.jmi.Callback;


public class ContextMenuHandler implements CefContextMenuHandler {
    
    private final Callback callback_ = new Callback();
    private final PageVisitor visitor = new PageVisitor(this.callback_);
    
    public ContextMenuHandler() {

    }

    @Override
    public void onBeforeContextMenu(
            CefBrowser browser, CefFrame frame, CefContextMenuParams params, CefMenuModel model) {
        model.clear();

        // Navigation menu
        model.addItem(MenuId.MENU_ID_BACK, "Back");
        model.setEnabled(MenuId.MENU_ID_BACK, browser.canGoBack());

        model.addItem(MenuId.MENU_ID_FORWARD, "Forward");
        model.setEnabled(MenuId.MENU_ID_FORWARD, browser.canGoForward());

        model.addSeparator();
        model.addItem(MenuId.MENU_ID_FIND, "Find...");
        if (params.hasImageContents() && params.getSourceUrl() != null)
            model.addItem(MenuId.MENU_ID_USER_FIRST, "Open image in imtool...");
        model.addItem(MenuId.MENU_ID_VIEW_SOURCE, "View Source...");
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
            default:
                return false;
        }
    }

    @Override
    public void onContextMenuDismissed(CefBrowser browser, CefFrame frame) {

    }
    
    public Callback getCallback(){
        
        return this.callback_;
    }
}
    
    class PageVisitor implements CefStringVisitor{
        
        private final Callback use_callback;
        
        public PageVisitor( Callback callback) {
            
            this.use_callback = callback;
        }   
 
         @Override
        public void visit(String string) {
            this.use_callback.postCallback(string);
        }
    }


