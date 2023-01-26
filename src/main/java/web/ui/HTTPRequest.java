package web.ui;

import org.cef.network.CefPostData;
import org.cef.network.CefPostDataElement;
import org.cef.network.CefRequest;
import org.cef.network.CefRequest.CefUrlRequestFlags;

import java.awt.BorderLayout;
//import java.awt.GridBagConstraints;
//import java.awt.GridBagLayout;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
//import java.awt.event.ActionListener;
import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
//import java.util.Vector;
import java.util.ArrayList;

import javax.swing.BorderFactory;
import javax.swing.ButtonGroup;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JScrollPane;
import javax.swing.JTable;
//import javax.swing.JTextField;
import javax.swing.JFrame;
import javax.swing.SwingUtilities;
import javax.swing.table.AbstractTableModel;
//import javax.swing.JTextArea;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;

import web.dialog.UrlRequestDialogReply;

import com.jidesoft.swing.LabeledTextField;
import com.jidesoft.swing.JideBoxLayout;
import com.jidesoft.swing.MultilineLabel;
import com.jidesoft.dialog.ButtonPanel;
import java.awt.Color;

@SuppressWarnings("serial")
public class HTTPRequest extends JFrame {
    private final ArrayList<JRadioButton> requestMethods = new ArrayList<>();
    private final Map<JCheckBox, Integer> requestFlags = new HashMap<>();
    private final TableModel headerTblModel = new TableModel(true);
    private final TableModel postDataModel = new TableModel(false);
    private final LabeledTextField urlField;
    private final LabeledTextField cookieUrl;
    private final MultilineLabel sentRequest_ = new MultilineLabel();
    private final UrlRequestDialogReply handleRequest;
    //private final CefRequest request;

    private CefRequest createRequest() {
        String url = urlField.getText();
        if (url.isEmpty() || url.trim().equalsIgnoreCase("http://")) {
            SwingUtilities.invokeLater(() -> {
                JOptionPane.showMessageDialog(this,
                        "Please specify at least an URL. Otherwise the CefRequest is invalid");
            });
            return null;
        }

        CefRequest request = CefRequest.create();
        if (request == null) return null;

        String firstPartyForCookie = cookieUrl.getText();
        if (firstPartyForCookie.isEmpty() || firstPartyForCookie.trim().equalsIgnoreCase("http://"))
            firstPartyForCookie = url;

        String method = "GET";
        for (int i = 0; i < requestMethods.size(); i++) {
            JRadioButton button = requestMethods.get(i);
            if (button.isSelected()) {
                method = button.getText();
                break;
            }
        }

        CefPostData postData = null;
        int postDataRows = postDataModel.getRowCount();
        if (postDataRows > 0) {
            postData = CefPostData.create();
        } else if (method.equalsIgnoreCase("POST") || method.equalsIgnoreCase("PUT")) {
            SwingUtilities.invokeLater(() -> {
                JOptionPane.showMessageDialog(
                        this, "The methods POST and PUT require at least one row of data.");
            });
            return null;
        }

        if (postData != null) {
            for (int i = 0; i < postDataRows; i++) {
                String value = (String) postDataModel.getValueAt(i, 0);
                if (value.trim().isEmpty()) continue;

                CefPostDataElement elem = CefPostDataElement.create();
                if (elem != null) {
                    File f = new File(value);
                    if (f.isFile()) {
                        elem.setToFile(value);
                    } else {
                        byte[] byteStr = value.getBytes();
                        elem.setToBytes(byteStr.length, byteStr);
                    }
                    postData.addElement(elem);
                }
            }
        }

        Map<String, String> headerMap = null;
        int headerRows = headerTblModel.getRowCount();
        if (headerRows > 0) {
            headerMap = new HashMap<>();
            for (int i = 0; i < headerRows; i++) {
                String key = (String) headerTblModel.getValueAt(i, 0);
                String value = (String) headerTblModel.getValueAt(i, 1);
                if (key.trim().isEmpty()) continue;

                headerMap.put(key, value);
            }
        }

        int flags = 0;
        Set<Entry<JCheckBox, Integer>> entrySet = requestFlags.entrySet();
        for (Entry<JCheckBox, Integer> entry : entrySet) {
            if (entry.getKey().isSelected()) {
                flags |= entry.getValue();
            }
        }

        request.set(url, method, postData, headerMap);
        request.setFirstPartyForCookies(firstPartyForCookie);
        request.setFlags(flags);
        return request;
    }

    public HTTPRequest(String title) {
        super(title);
        
        this.handleRequest =  new UrlRequestDialogReply(this, getTitle() + " - Result");
        
        JPanel urlPanel = createPanelWithTitle("Request URLs", 2, 0);
        // URL for the request
        urlField = new LabeledTextField(null,"Request URL :");
        urlField.setText("http://example.com");        

        // URL for the cookies
        cookieUrl = new LabeledTextField(null,"Cookie URL :");
        cookieUrl.setText("http://");
        
        urlPanel.add(urlField);
        urlPanel.add(cookieUrl);

        // Radio buttons for the request method
        ButtonGroup requestModeGrp = new ButtonGroup();
        JPanel requestModePanel = createPanelWithTitle("Request Mode", 0, 1);
        addRequestMode(requestModePanel, requestModeGrp, "GET", true);
        addRequestMode(requestModePanel, requestModeGrp, "HEAD", false);
        addRequestMode(requestModePanel, requestModeGrp, "POST", false);
        addRequestMode(requestModePanel, requestModeGrp, "PUT", false);
        addRequestMode(requestModePanel, requestModeGrp, "DELETE", false);

        // Checkboxes for the flags
        JPanel flagsPanel = createPanelWithTitle("Flags", 0, 1);
        addRequestFlag(flagsPanel, "Skip cache", CefUrlRequestFlags.UR_FLAG_SKIP_CACHE,
                "If set the cache will be skipped when handling the request", false);
        addRequestFlag(flagsPanel, "Allow cached credentials",
                CefUrlRequestFlags.UR_FLAG_ALLOW_CACHED_CREDENTIALS,
                "If set user name, password, and cookies may be sent with the request, "
                        + "and cookies may be saved from the response.",
                false);
        addRequestFlag(flagsPanel, "Report Upload Progress",
                CefUrlRequestFlags.UR_FLAG_REPORT_UPLOAD_PROGRESS,
                "If set upload progress events will be generated when a request has a body", false);
        addRequestFlag(flagsPanel, "Report RawHeaders",
                CefUrlRequestFlags.UR_FLAG_REPORT_RAW_HEADERS,
                "If set the headers sent and received for the request will be recorded", false);
        addRequestFlag(flagsPanel, "No download data", CefUrlRequestFlags.UR_FLAG_NO_DOWNLOAD_DATA,
                "If set the CefURLRequestClient.onDownloadData method will not be called", false);
        addRequestFlag(flagsPanel, "No retry on 5xx", CefUrlRequestFlags.UR_FLAG_NO_RETRY_ON_5XX,
                "If set 5XX redirect errors will be propagated to the observer instead of automatically re-tried.",
                false);
        
        JPanel requestPane = new JPanel();
        JideBoxLayout requestLayout = new JideBoxLayout(requestPane,JideBoxLayout.Y_AXIS);
        requestPane.setLayout(requestLayout);
        requestPane.setBorder(BorderFactory.createCompoundBorder(BorderFactory.createTitledBorder("HTTP-Request"),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)));
        //JPanel requestPane = createPanelWithTitle("HTTP-Request", 0, 2);
        
        sentRequest_.setOpaque(true);
        sentRequest_.setBackground(Color.WHITE);
        
        requestPane.add(new JScrollPane(sentRequest_),JideBoxLayout.VARY);
        
        JButton abortButton = new JButton("Abort");
        abortButton.addActionListener((ActionEvent e) -> {
            setVisible(false);
            dispose();
        });

        JButton sendButton;
        sendButton = new JButton("Send");
        sendButton.addActionListener((ActionEvent e) -> {
            CefRequest request = createRequest();
            if (request == null) return;
            handleRequest.send(request);
        });        

        ButtonPanel bottomPanel = new ButtonPanel(4,ButtonPanel.SAME_SIZE);
        bottomPanel.setBorder(BorderFactory.createEmptyBorder(4, 0, 4, 0));
        bottomPanel.add(abortButton,ButtonPanel.CANCEL_BUTTON);
        bottomPanel.add(sendButton,ButtonPanel.AFFIRMATIVE_BUTTON);
        
        requestPane.add(bottomPanel,JideBoxLayout.FIX);
        
        JPanel optionsPanel = new JPanel();
        JideBoxLayout layout = new JideBoxLayout(optionsPanel,JideBoxLayout.X_AXIS);
        optionsPanel.setLayout(layout);
        
        optionsPanel.add(requestModePanel,JideBoxLayout.FIX);
        optionsPanel.add(flagsPanel,JideBoxLayout.FIX);
        optionsPanel.add(requestPane,JideBoxLayout.VARY);        

        // Table for header values
        JPanel headerValues = createPanelWithTable("Header Values", headerTblModel);
        headerTblModel.addEntry("User-Agent", "Mozilla/5.0 JCEF Example Agent");
        headerTblModel.addEntry("Accept",
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");

        // Table for post-data
        JPanel postData = createPanelWithTable("Post Data", postDataModel);

        JPanel centerPanel = new JPanel(new GridLayout(2, 0));
        centerPanel.add(headerValues);
        centerPanel.add(postData);

        sentRequest_.setText(createRequest().toString());
        
        setSize(800, 1000);
        JPanel contentPane = (JPanel) this.getContentPane();
        contentPane.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        JideBoxLayout mainLayout = new JideBoxLayout(contentPane,JideBoxLayout.Y_AXIS);
        contentPane.setLayout(mainLayout);        

        contentPane.add(urlPanel, JideBoxLayout.FIX);
        contentPane.add(optionsPanel, JideBoxLayout.FIX);
        contentPane.add(centerPanel, JideBoxLayout.VARY);
        //contentPane.add(bottomPanel, JideBoxLayout.FIX);
        
        setLocationRelativeTo(null);
        setVisible(true);
        handleRequest.setVisible(true);
    }

    private void addRequestMode(
            JPanel panel, ButtonGroup buttonGrp, String requestMode, boolean selected) {
        JRadioButton button = new JRadioButton(requestMode, selected);
        buttonGrp.add(button);
        panel.add(button);
        requestMethods.add(button);
    }

    private void addRequestFlag(
            JPanel panel, String flag, int value, String tooltip, boolean selected) {
        JCheckBox checkBox = new JCheckBox(flag, selected);
        checkBox.setToolTipText(tooltip);
        panel.add(checkBox);
        requestFlags.put(checkBox, value);
    }

    private JPanel createPanelWithTitle(String title, int rows, int cols) {
        JPanel result = new JPanel(new GridLayout(rows, cols,4,2));
        result.setBorder(BorderFactory.createCompoundBorder(BorderFactory.createTitledBorder(title),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)));
        return result;
    }

    private JPanel createPanelWithTable(String title, TableModel tblModel) {
        final TableModel localTblModel = tblModel;
        JPanel result = new JPanel(new BorderLayout());
        result.setBorder(BorderFactory.createCompoundBorder(BorderFactory.createTitledBorder(title),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)));

        JTable table = new JTable(tblModel);
        table.setFillsViewportHeight(true);
        JScrollPane scrollPane = new JScrollPane(table);

        //JPanel buttonPane = new JPanel(new GridLayout(0, 2));
        ButtonPanel buttonPane = new ButtonPanel(4,ButtonPanel.SAME_SIZE);
        buttonPane.setBorder(BorderFactory.createEmptyBorder(4, 0, 4, 0));
        JButton addButton = new JButton("Add entry");
        addButton.addActionListener((ActionEvent e) -> {
            localTblModel.newDefaultEntry();
        });
        buttonPane.add(addButton,ButtonPanel.AFFIRMATIVE_BUTTON);

        JButton delButton = new JButton("Remove entry");
        delButton.addActionListener((ActionEvent e) -> {
            localTblModel.removeSelected();
        });
        buttonPane.add(delButton,ButtonPanel.CANCEL_BUTTON);

        result.add(scrollPane, BorderLayout.CENTER);
        result.add(buttonPane, BorderLayout.PAGE_END);

        return result;
    }

    private class TableModel extends AbstractTableModel {
        private final String[] columnNames;
        private final ArrayList<Object[]> rowData = new ArrayList<>();
        private final boolean hasKeyColumn_;

        public TableModel(boolean hasKeyColumn) {
            super();
            hasKeyColumn_ = hasKeyColumn;
            if (hasKeyColumn)
                columnNames = new String[] {"Key", "Value", ""};
            else
                columnNames = new String[] {"Value", ""};
        }

        public void newDefaultEntry() {
            int row = rowData.size();
            if (hasKeyColumn_) {
                Object[] rowEntry = {"key", "value", false};
                rowData.add(rowEntry);
            } else {
                Object[] rowEntry = {"value", false};
                rowData.add(rowEntry);
            }
            fireTableRowsInserted(row, row);
        }

        public void removeSelected() {
            int idx = hasKeyColumn_ ? 2 : 1;
            for (int i = 0; i < rowData.size(); ++i) {
                if ((Boolean) rowData.get(i)[idx]) {
                    rowData.remove(i);
                    fireTableRowsDeleted(i, i);
                    i--;
                }
            }
        }

        public void addEntry(String key, String value) {
            int row = rowData.size();
            if (hasKeyColumn_) {
                Object[] rowEntry = {key, value, false};
                rowData.add(rowEntry);
            } else {
                Object[] rowEntry = {value, false};
                rowData.add(rowEntry);
            }
            fireTableRowsInserted(row, row);
        }

        @Override
        public int getRowCount() {
            return rowData.size();
        }

        @Override
        public int getColumnCount() {
            return columnNames.length;
        }

        @Override
        public String getColumnName(int column) {
            return columnNames[column];
        }

        @Override
        public Class<?> getColumnClass(int columnIndex) {
            if (!rowData.isEmpty()) return rowData.get(0)[columnIndex].getClass();
            return Object.class;
        }

        @Override
        public boolean isCellEditable(int rowIndex, int columnIndex) {
            return true;
        }

        @Override
        public Object getValueAt(int rowIndex, int columnIndex) {
            return rowData.get(rowIndex)[columnIndex];
        }

        @Override
        public void setValueAt(Object aValue, int rowIndex, int columnIndex) {
            rowData.get(rowIndex)[columnIndex] = aValue;
            fireTableCellUpdated(rowIndex, columnIndex);
        }
    }
    
    /*private class UrlRequestReply implements CefURLRequestClient{
        private CefURLRequest urlRequest_ = null;
        private final ByteArrayOutputStream byteStream_ = new ByteArrayOutputStream();
        private final Frame caller_;
        
        public UrlRequestReply( HTTPRequest caller ){
            this.caller_ = caller;
        }
        
        public void send(CefRequest request) {
            if (request == null) {
                statusLabel_.setText("HTTP-Request status: FAILED");
                sentRequest_.append("Can't send CefRequest because it is NULL");
                cancelButton_.setEnabled(false);
                return;
        }

        urlRequest_ = CefURLRequest.create(request, this);
        if (urlRequest_ == null) {
            statusLabel_.setText("HTTP-Request status: FAILED");
            sentRequest_.append("Can't send CefRequest because creation of CefURLRequest failed.");
            repliedResult_.append(
                    "The native code (CEF) returned a NULL-Pointer for CefURLRequest.");
            cancelButton_.setEnabled(false);
        } else {
            sentRequest_.append(request.toString());
            cancelButton_.setEnabled(true);
            updateStatus("", false);
        }
    }

        @Override
        public void onRequestComplete(CefURLRequest curlr) {
            throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
        }

        @Override
        public void onUploadProgress(CefURLRequest curlr, int i, int i1) {
            throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
        }

        @Override
        public void onDownloadProgress(CefURLRequest curlr, int i, int i1) {
            throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
        }

        @Override
        public void onDownloadData(CefURLRequest curlr, byte[] bytes, int i) {
            throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
        }

        @Override
        public boolean getAuthCredentials(boolean bln, String string, int i, String string1, String string2, CefAuthCallback cac) {
            throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
        }

        @Override
        public void setNativeRef(String string, long l) {
            throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
        }

        @Override
        public long getNativeRef(String string) {
            throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
        }
        
    }*/
}
       