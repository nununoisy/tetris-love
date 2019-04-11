function love.conf(t)
    t.identity = "tetrislove"

    t.externalstorage = false           
    
    t.audio.mixwithsystem = true        
 
    t.window.title = "tetris-love"         
    t.window.icon = "images/tetris-love-logo.png"                 
    t.window.width = 800                
    t.window.height = 700               
    t.window.borderless = false         
    t.window.resizable = false
    
    t.window.highdpi = true
    
    t.modules.physics = false
end