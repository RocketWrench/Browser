function testjs

    htmlfile = 'gage.html';
    htmlcode = readlines(htmlfile,'EmptyLineRule','skip','WhitespaceRule','trim');
    htmlcode = char(join(htmlcode));

    jscode = 'var canvasLeft = document.getElementById("right");ctx = canvasLeft.getContext("2d");ctx.font = "40px Arial";ctx.strokeText("Right Side",10,60)';

    b = Browser([],figure('Position',[447 702 700 400]));
    drawnow()
    b.loadString(htmlcode)
    drawnow()
    pause(0.5)
    b.executeJavaScript(jscode,b.URL,0)
    
end    
