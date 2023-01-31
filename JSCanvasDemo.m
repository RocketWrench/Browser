function JSCanvasDemo()
    
    % id's for HTML elements (Canvas, Plotly)
    mousePosCanvasID = 'mousePosCanvas';
    clockCanvasID = 'clockCanvas';
    detailCanvasID = 'detailCanvas';
    ballCanvasID = 'ballCanvas';
    
    dimA = 140;
    dimB = 190;
    dim = [dimA,dimA];

    fig = figure(...
        'Color','w',...
        'Name','JavaScript Demo',...
        'ToolBar','none',...
        'MenuBar','none',...
        'NumberTitle','off');

    container = Browser.createFlowContainer(fig,'topdown');
    container.Margin = 1;
    a = Browser.createPanel(container,dim,[]);
    topFlowContainer = Browser.createFlowContainer(a,'lefttoright');
    topFlowContainer.Margin = 2;
    topPanel = Browser.createPanel(topFlowContainer,dim,[dimB,dimB]);
    middlePanel = Browser.createPanel(topFlowContainer,dim,[]);
    cornerPanel = Browser.createPanel(topFlowContainer,dim,dim);
    a = Browser.createPanel(container);
    botFlowContainer = Browser.createFlowContainer(a,'lefttoright');
    botFlowContainer.Margin = 2;
    axesPanel = Browser.createPanel(botFlowContainer);
    axesPanel.BackgroundColor = 'w';
    rightPanel = Browser.createPanel(botFlowContainer);
    
    ax = axes('Parent',axesPanel);
    I = imread('moon.tif');
    imshow(I,'Parent',ax);
    ax.Units = 'normalized';
    ax.Position = [0,0,1,1];
    ax.Toolbar = [];
    ax.XAxis.Visible = 'off';
    ax.YAxis.Visible = 'off';

    set(ax,'LooseInset',get(ax,'TightInset')) 

    roi = images.roi.Rectangle(...
        'Parent',ax,...
        'Position',[1,1,51,51],...
        'ContextMenu',[],...
        'InteractionsAllowed','translate');
    addlistener(roi,'ROIMoved',@onROIMoved);

    browserMousePos = Browser.getCanvasBrowser(topPanel); 
    browserClock = Browser.getCanvasBrowser(cornerPanel); 
    browserDetail = Browser.getCanvasBrowser(middlePanel); 
    browserBall = Browser.getCanvasBrowser(rightPanel); 

    browserMousePos.loadString(getCanvasHTML(mousePosCanvasID,300,dimA));
    browserClock.loadString(getCanvasHTML(clockCanvasID,dimA,dimA)); 
    browserDetail.loadString(getPlotlyHTML(detailCanvasID));
    browserBall.loadString(getCanvasHTML(ballCanvasID,dimA,300));

    drawnow();
    pause(0.5)

    browserClock.executeJavaScript(getAnimatedClockJSCode(clockCanvasID))
    browserBall.executeJavaScript('ball.js')
    onROIMoved(roi,[]); 

    function onROIMoved( src, ~ )
    
        mask = createMask(roi);
        data = I(mask);
        x = sprintf('x: %2.1f',src.Position(1));
        y = sprintf('y: %2.1f',src.Position(2)); 
        wid = sprintf('width: %2.1f',sum(src.Position(1,[1,3])));
        hgt = sprintf('hieght: %2.1f',sum(src.Position(1,[2,4]))); 
        browserDetail.executeJavaScript(histogramJS(detailCanvasID,data),[],0);  
        jscode = "var c = document.getElementById('" + mousePosCanvasID + "');";
        jscode = jscode + "ctx = c.getContext('2d');";
        jscode = jscode + "ctx.clearRect(0,0,c.width,c.height);";
        jscode = jscode + "ctx.font = '30px Arial';";
        jscode = jscode + "ctx.strokeText('" + x + "',10,30);";
        jscode = jscode + "ctx.strokeText('" + y + "',10,60);";
        jscode = jscode + "ctx.strokeText('" + wid + "',10,90);";
        jscode = jscode + "ctx.strokeText('" + hgt + "',10,120);";
        browserMousePos.executeJavaScript(char(jscode),[],0); 
    end
end

function html = getCanvasHTML( id, wid, hgt )
    html = "<!DOCTYPE HTML><html>";
    html = html + "<head><style>body{width: 100%; height: 100%; margin: 0px; overflow: hidden}</style></head><body>";
    html = html + "<canvas id=" +id + " style = position : relative; style = display : block; width= " + wid + " height= " + hgt + "></canvas>";
    html = html + "<script type='text/javascript'> ";
    html = html + "window.addEventListener('resize', resizeCanvas, false);";
    html = html + "function resizeCanvas(e) {var canvas = document.getElementById(" + id + "); canvas.width = document.documentElement.clientWidth; canvas.height = document.documentElement.clientHeight; drawScreen();}</script>";
    html = html + "</body></html>";
    html = char(html);
end

function html = getPlotlyHTML( id )
    html = "<!DOCTYPE HTML><html>";
    html = html + "<head><style>body{width: 100%; height: 140px; margin: 0px; overflow: hidden;}</style><script src='https://cdn.plot.ly/plotly-2.18.0.min.js'></script></head><body>";
    html = html + "<div id=" + id + " style=width:100%;height:140px;></div>";
    html = html + "</body></html>";   
    html = char(html);
end

function jscode = getAnimatedClockJSCode(id)

% from https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Basic_animations
     jscode =  ['function clock() {',...
      'const now = new Date();'...
      sprintf('const canvas = document.getElementById("%s");',id),...
      'const ctx = canvas.getContext("2d");',...
      'ctx.save();',...
      'ctx.clearRect(0, 0, 150, 150);',...
      'ctx.translate(75, 75);',...
      'ctx.scale(0.4, 0.4);',...
      'ctx.rotate(-Math.PI / 2);',...
      'ctx.strokeStyle = "black";',...
      'ctx.fillStyle = "white";',...
      'ctx.lineWidth = 8;',...
      'ctx.lineCap = "round";',...     
      'ctx.save();',...
      'for (let i = 0; i < 12; i++) {',...
        'ctx.beginPath();',...
        'ctx.rotate(Math.PI / 6);',...
        'ctx.moveTo(100, 0);',...
        'ctx.lineTo(120, 0);',...
        'ctx.stroke();',...
      '}',...
      'ctx.restore();',...       
      'ctx.save();',...
      'ctx.lineWidth = 5;',...
      'for (let i = 0; i < 60; i++) {',...
       'if (i % 5 !== 0) {',...
          'ctx.beginPath();',...
          'ctx.moveTo(117, 0);',...
          'ctx.lineTo(120, 0);',...
          'ctx.stroke();',...
        '}',...
        'ctx.rotate(Math.PI / 30);',...
      '}',...
      'ctx.restore();',...        
      'const sec = now.getSeconds();',...
      'const min = now.getMinutes();',...
      'const hr = now.getHours();',...        
      'ctx.fillStyle = "black";',...
      'canvas.innerText = `The time is: ${hr}:${min}`;',...        
      'ctx.save();',...
      'ctx.rotate((Math.PI / 6) * hr + (Math.PI / 360) * min + (Math.PI / 21600) * sec);',...
      'ctx.lineWidth = 14;',...
      'ctx.beginPath();',...
      'ctx.moveTo(-20, 0);',...
      'ctx.lineTo(80, 0);',...
      'ctx.stroke();',...
      'ctx.restore();',...        
      'ctx.save();',...
      'ctx.rotate((Math.PI / 30) * min + (Math.PI / 1800) * sec);',...
      'ctx.lineWidth = 10;',...
      'ctx.beginPath();',...
      'ctx.moveTo(-28, 0);',...
      'ctx.lineTo(112, 0);',...
      'ctx.stroke();',...
      'ctx.restore();',...
      'ctx.save();',...
      'ctx.rotate((sec * Math.PI) / 30);',...
      'ctx.strokeStyle = "#D40000";',...
      'ctx.fillStyle = "#D40000";',...
      'ctx.lineWidth = 6;',...
      'ctx.beginPath();',...
      'ctx.moveTo(-30, 0);',...
      'ctx.lineTo(83, 0);',...
      'ctx.stroke();',...
      'ctx.beginPath();',...
      'ctx.arc(0, 0, 10, 0, Math.PI * 2, true);',...
      'ctx.fill();',...
      'ctx.beginPath();',...
      'ctx.arc(95, 0, 10, 0, Math.PI * 2, true);',...
      'ctx.stroke();',...
      'ctx.fillStyle = "rgba(0, 0, 0, 0)";',...
      'ctx.arc(0, 0, 3, 0, Math.PI * 2, true);',...
      'ctx.fill();',...
      'ctx.restore();',...        
      'ctx.beginPath();',...
      'ctx.lineWidth = 14;',...
      'ctx.strokeStyle = "#325FA2";',...
      'ctx.arc(0, 0, 142, 0, Math.PI * 2, true);',...
      'ctx.stroke();',...        
      'ctx.restore();',...        
      'window.requestAnimationFrame(clock);',...
    '}',...        
    'window.requestAnimationFrame(clock);'];
end

function jscode = histogramJS( id, roi )
    roi = roi(:)';
    roistr = string(roi);
   
    jscode = " var x = [" + strjoin(roistr,",") + "];";
    jscode = jscode + "var trace = { x: x, type: 'histogram', xbins: {end:255, size: 1, start:0}, nbinsx: 256};";
    jscode = jscode + "var data = [trace]; ";
    jscode = jscode +  "Plotly.newPlot(" + string(['"',id,'"']) + ", data,";
    jscode = jscode + " {margin:{ t: 0, r: 20, l: 30, b : 20 }, autosize:true,";
    jscode = jscode + "xaxis: {range: [0,255], tick0: 0, dtick: 64}},";
    %jscode = jscode + "yaxis: {autorange: true, showgrid: false, zeroline: false, showline: false, autotick: true, ticks: '', showticklabels: false}},";
    jscode = jscode + "{responsive:true});";
    jscode = char(jscode);
    %jscode = [jscode,'Plotly.newPlot(canvas,[{x: [1, 2, 3, 4, 5],y: [1, 2, 4, 8, 16]}],{margin:{ t: 0, r: 20, l: 20, b : 20 }, autosize:true},{responsive:true});'];

end

   