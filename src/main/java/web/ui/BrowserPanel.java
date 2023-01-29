package web.ui;

import java.awt.Component;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
//import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.Dimension;
import java.awt.KeyboardFocusManager;
import java.awt.event.FocusAdapter;
import java.awt.event.FocusEvent;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.FocusManager;
import javax.swing.SwingUtilities;
import javax.swing.BorderFactory;
import javax.swing.ImageIcon;

import org.cef.browser.CefBrowser;
import org.cef.CefClient;
import org.cef.handler.CefFocusHandler;
import org.cef.OS;
import org.cef.handler.CefLoadHandlerAdapter;
import org.cef.handler.CefLoadHandler;
import org.cef.browser.CefFrame;
import org.cef.network.CefRequest;
import org.cef.handler.CefDisplayHandlerAdapter;
import org.cef.CefSettings;
import org.cef.handler.CefFocusHandlerAdapter;

import com.jidesoft.swing.JideBoxLayout;
import com.jidesoft.swing.PartialLineBorder;
import com.jidesoft.swing.NullJideButton;
import com.jidesoft.swing.LabeledTextField;
import com.jidesoft.document.DefaultStringConverter;
import com.jidesoft.swing.SelectAllUtils;

import com.mathworks.jmi.Callback;
import com.mathworks.desktop.overlay.impl.DefaultOverlayManager;


import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import javax.swing.JTextField;
import javax.swing.UIManager;

import web.BrowserEventData;
import web.EventType;


public final class BrowserPanel extends JPanel{
    private CefBrowser browser_;
    private AddressPane addressPane_ ;
    private final JFrame panel_owner_;
    private boolean has_address_pane = false;
    private boolean add_started_ = false;
    private LoadHandler load_handler_;
    private DisplayHandler display_handler_;
    private CEFFocusManager focusManager_;
    
    public BrowserPanel( CefBrowser browser ){
        this(browser,false);
    }
    
    public BrowserPanel( CefBrowser browser, boolean hasAddressPane ){
        
        this.browser_ = browser;
        this.has_address_pane = hasAddressPane;
        
        setLayout(new BorderLayout());   
        setName("BrowserPanel");
        setBackground(Color.WHITE);
        DefaultOverlayManager.tagAsHeavyweight(BrowserPanel.this);

        this.panel_owner_ = new JFrame();
        this.panel_owner_.setName("BrowserPanelOwner");
        this.panel_owner_.add(BrowserPanel.this);
        this.panel_owner_.setVisible(false);
        this.panel_owner_.addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent event){
                BrowserPanel.this.browser_.setCloseAllowed();
                BrowserPanel.this.browser_.close(true);
                CEFFocusManager.uninstall(browser_, focusManager_);
            }
        });
        
        this.browser_.setFocusable(false);
        setupBrowserUIComponent();
        this.browser_.createImmediately();
        putClientProperty("CEFBrowser", this.browser_);
        add(this.browser_.getUIComponent(),"Center");
        this.focusManager_ = CEFFocusManager.install(this.browser_);
        CefClient client = this.browser_.getClient();
        if (this.has_address_pane) {
            this.addressPane_ = new AddressPane(this.browser_);
            add(this.addressPane_,"North"); 
            this.addressPane_.getTextField().addFocusListener(new FocusAdapter(){            
                @Override
                public void focusGained(FocusEvent event){
                    if (browserHasFocus()){
                        KeyboardFocusManager.getCurrentKeyboardFocusManager().clearGlobalFocusOwner();
                        BrowserPanel.this.addressPane_.getTextField().requestFocus();
                    }
                }
            });
            
            client.addFocusHandler( new CefFocusHandlerAdapter(){                
                @Override
                public void onGotFocus(CefBrowser browser){
                    if (browserHasFocus()){
                        KeyboardFocusManager.getCurrentKeyboardFocusManager().clearGlobalFocusOwner();
                        browser.setFocus(true);
                    }
                }
            });
        }
        
        
        this.load_handler_ = new LoadHandler(this);
        client.removeLoadHandler();
        client.addLoadHandler(this.load_handler_);
        this.display_handler_ = new DisplayHandler(this);
        client.removeDisplayHandler();
        client.addDisplayHandler(this.display_handler_);        
        client.removeFocusHandler();
        client.addFocusHandler(new CefFocusHandler() {
          @Override
          public void onTakeFocus(CefBrowser param1CefBrowser, boolean param1Boolean) {}
          
          @Override
          public boolean onSetFocus(CefBrowser param1CefBrowser, CefFocusHandler.FocusSource param1FocusSource) {
            if (OS.isLinux()) {
              BrowserPanel.this.onFocusHandler();
              return false;
            } 
            return OS.isMacintosh() && !BrowserPanel.this.browser_.isFocusable();
          }
          
          @Override
          public void onGotFocus(CefBrowser param1CefBrowser) {
            if (OS.isLinux())
              return; 
            BrowserPanel.this.onFocusHandler();
          }
        });
    }
    
    @Override
    public void requestFocus(){
        if (BrowserPanel.this.browser_ != null){
            BrowserPanel.this.browser_.setFocusable(true); 
            requestFocusInWindowOnEDT();
        }
    }

    @Override
    public void addNotify(){
        super.addNotify();
        if (BrowserPanel.this.browser_ != null){
            BrowserPanel.this.add_started_ = true;
        }
    }
            
    @Override
    public void removeNotify(){
        super.removeNotify();
    }
            
    @Override
    public void setBackground(Color new_color){
        super.setBackground(new_color);
        if (BrowserPanel.this.browser_ != null)
            BrowserPanel.this.browser_.getUIComponent().setBackground(new_color);                    
    }
    
    private void setupBrowserUIComponent(){
         this.browser_.getUIComponent().addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent event){
                super.mousePressed(event);
                if (!BrowserPanel.this.browserHasFocus())
                    BrowserPanel.this.browser_.setFocusable(true);
                BrowserPanel.this.requestFocusInWindowOnEDT();
            }
        });      
    }
    
    private void onFocusHandler() {
    if (browserHasFocus() || !this.browser_.isFocusable())
      return; 
    requestFocusInWindowOnEDT();
  }
      
    private boolean browserHasFocus(){
        Component component = FocusManager.getCurrentManager().getFocusOwner();
        return this.browser_.getUIComponent().equals(component);
    }
    
    private void requestFocusInWindowOnEDT(){
        Runnable runnable = () -> {
            BrowserPanel.this.browser_.getUIComponent().requestFocusInWindow();
        };
        if (SwingUtilities.isEventDispatchThread()) {
            runnable.run();
        }else if (BrowserPanel.this.browserHasFocus()){
            SwingUtilities.invokeLater(runnable);
        }         
    }
    
    public boolean hasAddressPane(){
        return this.has_address_pane;
    }
    
    public void update(CefBrowser browser, boolean isLoading, boolean canGoBack, boolean canGoForward) {
        if (this.has_address_pane) {
            this.addressPane_.update(browser,isLoading,canGoBack,canGoForward);
        } 
    }
    
    public void setAddress(CefBrowser browser, String address){
        if (this.has_address_pane){
            this.addressPane_.setAddress(browser, address);
        }
    }
    
    public Callback getLoadHandlerCallback(){
        return this.load_handler_.getCallback();
    }
    
    public Callback getDisplayHandlerCallback(){
        return this.display_handler_.getCallback();
    }
    
    private class AddressPane extends JPanel{
        
        private CefBrowser browser_;
        private final NullJideButton backButton_;
        private final NullJideButton forwardButton_;
        private final NullJideButton reloadButton_;
        private final NullJideButton homeButton_;
        private final JTextField addressField_;
        private boolean isLoading = false;
        //private static final Color BACKGROUND_COLOR = UIManager.getColor("Panel.background");
        
        AddressPane( CefBrowser browser ){
            this.browser_ = browser;
            setBackground(Color.WHITE);
            setLayout(new JideBoxLayout(this,JideBoxLayout.X_AXIS,6));
            setBorder(BorderFactory.createCompoundBorder(new PartialLineBorder(new Color(0.9F,0.9F,0.9F,0.6F),2,PartialLineBorder.SOUTH),BorderFactory.createEmptyBorder(4,2,4,2)));
            
            this.backButton_ = new NullJideButton(getIcon("icons/back.png"));
            this.backButton_.setEnabled(this.browser_.canGoBack());
            this.backButton_.setFocusable(false);
            this.backButton_.addActionListener((ActionEvent event) -> {
                AddressPane.this.browser_.goBack();
            });
            
            this.forwardButton_ = new NullJideButton(getIcon("icons/forward.png"));
            this.forwardButton_.setEnabled(this.browser_.canGoForward());
            this.forwardButton_.setFocusable(false);
            this.forwardButton_.addActionListener((ActionEvent event) -> {
                AddressPane.this.browser_.goForward();
            });
            
            this.reloadButton_ = new NullJideButton(getIcon("icons/refresh.png"));
            this.reloadButton_.setFocusable(false);
            this.reloadButton_.addActionListener((ActionEvent event) -> {
                if (!AddressPane.this.isLoading){
                    byte b = (byte) (OS.isMacintosh()? 4 : 2);
                    int code = b & event.getModifiers(); 
                    boolean state = 0 != code;
                    if (state){
                        AddressPane.this.browser_.reloadIgnoreCache();
                    } else{
                        AddressPane.this.browser_.reload();
                    }
                } else {
                    AddressPane.this.browser_.stopLoad();
                }
            });
            
            this.homeButton_ = new NullJideButton(getIcon("icons/home.png"));
            this.homeButton_.setFocusable(false);
            this.homeButton_.addActionListener((ActionEvent event) -> {
                AddressPane.this.browser_.loadURL("www.google.com");
            });
            
            this.addressField_ = new JTextField();
              //this.addressField_.setBorder(BorderFactory.createEmptyBorder(0,8,0,0));
            this.addressField_.setBackground(UIManager.getColor("Panel.background"));
            //this.addressField_.setPreferredSize(new Dimension(100,36));
            this.addressField_.addActionListener((ActionEvent event) -> {
                AddressPane.this.browser_.loadURL(AddressPane.this.getAddress());
            });
            this.addressField_.addMouseListener(new MouseAdapter(){
                @Override
                public void mouseClicked(MouseEvent evnt){
                    KeyboardFocusManager.getCurrentKeyboardFocusManager().clearGlobalFocusOwner();
                    AddressPane.this.addressField_.requestFocus();
                }
            });
            /*this.addressField_.addComponentListener(new ComponentAdapter(){
                public void componentRized(ComponentEvent event){
                    JTextField textField = AddressPane.this.addressField_.getTextField();
                    int textWidth = textField.getFontMetrics(textField.getFont()).stringWidth(textField.getText());
                    int componentWidth = event.getComponent().getWidth();
                    if (textWidth > componentWidth){
                        int n = ((textWidth - componentWidth)> 3) ? textWidth - componentWidth : 3;
                        DefaultStringConverter strConverter = new DefaultStringConverter(n,0);
                        textField.setText(strConverter.convert(textField.getText()));
                    }
                }
            });*/
            SelectAllUtils.install(this.addressField_,true);
            this.add(this.backButton_,JideBoxLayout.FIX);
            this.add(this.forwardButton_,JideBoxLayout.FIX);
            this.add(this.reloadButton_,JideBoxLayout.FIX);
            this.add(this.homeButton_,JideBoxLayout.FIX);
            this.add(new AddressFieldPanel(this.addressField_),JideBoxLayout.VARY);
        }
        
        private ImageIcon getIcon(String iconFile){
            ClassLoader classLoader = BrowserPanel.class.getClassLoader();
            URL url = classLoader.getResource(iconFile);
            return new ImageIcon(url);
        }
        
        
        public String getAddress() {
            String str = this.addressField_.getText();
            try {
                str = str.replaceAll(" ", "%20");
                URI uRI = new URI(str);
                if (uRI.getScheme() != null)
                    return str; 
                if (uRI.getHost() != null && uRI.getPath() != null)
                    return str; 
                String str1 = uRI.getSchemeSpecificPart();
                if (str1.indexOf('.') == -1)
                throw new URISyntaxException(str1, "No dot inside domain"); 
            } catch (URISyntaxException uRISyntaxException) {
                str = "google.com/search?q=" + str;
            } 
            return str;
        }
        
        public void update(CefBrowser browser, boolean isLoading, boolean canGoBack, boolean canGoForward) {
            if (browser == this.browser_) {
                this.backButton_.setEnabled(canGoBack);
                this.forwardButton_.setEnabled(canGoForward);
                this.isLoading = isLoading;
                this.revalidate();
                this.repaint();
            } 
        }
        
        public void setAddress(CefBrowser browser, String address){
            if (browser == this.browser_){
                this.addressField_.setText(address);
                this.addressField_.repaint();
            }
        }
        
        public JTextField getTextField(){
            return this.addressField_;
        }
    }
    
    private class LoadHandler extends CefLoadHandlerAdapter{
        private final Callback callback_ = new Callback();
        private final BrowserPanel browserPanel;
        
        LoadHandler( BrowserPanel panel ){
            
            this.browserPanel = panel;
        }
        @Override
        public void onLoadingStateChange(CefBrowser browser,
                                     boolean isLoading,
                                     boolean canGoBack,
                                     boolean canGoForward){            
 
            if (browser.getUIComponent().getParent() == this.browserPanel && this.browserPanel.hasAddressPane()){
                Runnable runnable = () -> {
                    this.browserPanel.update(browser, isLoading, canGoBack, canGoForward);
                };
                if (SwingUtilities.isEventDispatchThread()) {
                    runnable.run();
                }else {
                    SwingUtilities.invokeLater(runnable);
                }                    
            }

            this.callback_.postCallback(new BrowserEventData(browser,isLoading,canGoBack,canGoForward));
        }
    
        @Override
        public void onLoadStart(CefBrowser browser,
                            CefFrame frame,
                            CefRequest.TransitionType transitionType){

            this.callback_.postCallback(new BrowserEventData(browser,frame,transitionType));
        }
    
        @Override
        public void onLoadEnd(CefBrowser browser,
                          CefFrame frame,
                          int httpStatusCode){

            this.callback_.postCallback(new BrowserEventData(browser,frame,httpStatusCode));
        }
    
        @Override
        public void onLoadError(CefBrowser browser,
                            CefFrame frame,
                            CefLoadHandler.ErrorCode errorCode,
                            String errorText,
                            String failedUrl){

            this.callback_.postCallback(new BrowserEventData(browser,frame,errorCode,errorText,failedUrl));
        }
    
        public Callback getCallback(){
        
        return this.callback_;
        }

    }  
    
    private class DisplayHandler extends CefDisplayHandlerAdapter{
        private final Callback callback_ = new Callback();
        private final BrowserPanel browserPanel;
        
        DisplayHandler( BrowserPanel panel ){
            this.browserPanel = panel;
        }
    
        @Override
        public void onAddressChange(CefBrowser browser, CefFrame frame, String url){
            
            if (browser.getUIComponent().getParent() == this.browserPanel && this.browserPanel.hasAddressPane()){                    
                Runnable runnable = () -> {
                    this.browserPanel.setAddress(browser,url);
                };
                if (SwingUtilities.isEventDispatchThread()) {
                    runnable.run();
                }else {
                    SwingUtilities.invokeLater(runnable);
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
}
