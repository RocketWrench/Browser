package web;

import javax.swing.SwingUtilities;
import org.cef.handler.CefDisplayHandlerAdapter;
import org.cef.browser.CefBrowser;
import org.cef.browser.CefFrame;
import org.cef.CefSettings;
import com.mathworks.jmi.Callback;
import web.ui.BrowserPanel;
        
public class DisplayHandler extends CefDisplayHandlerAdapter{
    
    private final Callback callback_ = new Callback();
    
    @Override
    public void onAddressChange(CefBrowser browser, CefFrame frame, String url){
         if (browser.getUIComponent().getParent() != null){
            if (browser.getUIComponent().getParent().getName().equalsIgnoreCase("BrowserPanel")){
                BrowserPanel parent = (BrowserPanel) browser.getUIComponent().getParent();
                if (parent.hasAddressPane()){
                    parent.setAddress(browser, url);
                    System.out.println("OnAddressChange");
                }
            }
        }       
        this.callback_.postCallback(new BrowserEventData(browser,frame,url));
    }
    
    @Override
    public void onTitleChange(CefBrowser browser, String title){

        this.callback_.postCallback(new BrowserEventData(browser,EventType.TITLE_CHANGE,title));    
    }

    @Override
    public boolean onTooltip(CefBrowser browser, String text){
        this.callback_.postCallback(new BrowserEventData(browser,EventType.TOOLTIP,text)); 
        return false;        
    }
    
    @Override
    public void onStatusMessage(CefBrowser browser, String message) {
        if (!message.isEmpty())
            this.callback_.postCallback(new BrowserEventData(browser,EventType.STATUS_MESSAGE,message));       
    }

    @Override
    public boolean onConsoleMessage(CefBrowser browser, 
                                    CefSettings.LogSeverity level,
                                    String message, String source, int line) {

        this.callback_.postCallback(new BrowserEventData(browser,level,message,source,line)); 
        return false;        
    }

    @Override
    public boolean onCursorChange(CefBrowser browser, int cursorIdentifer) {
        SwingUtilities.invokeLater(() -> {
        });       
        return false;        
    }
    
    public Callback getCallback(){
        
        return this.callback_;
    }

}
