package example

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

placementTexture: rl.Texture2D
rotationTexture: rl.Texture2D

Tool :: enum {
    MOVE,
    ROTATE,
}
TOOL_COUNT :: len(Tool)

OutputFormat :: enum {
    Swift,
}

Frame :: struct {
    placements: [dynamic]rl.Vector2,
    rotations: [dynamic]f32
}

Settings :: struct {
    screenWidth: i32,
    screenHeight: i32,
}

NameAndTexture :: struct {
    name: cstring,
    texture: ^rl.Texture2D
}

Editor :: struct {
    settings: ^Settings,
    camera: ^rl.Camera2D,
    activeTool: Tool,
    activeFrame: i32,
    scrollBarPosition_t: f32,
    frames: [dynamic]^Frame,
    assets: [dynamic]NameAndTexture,
}

outputFrame :: proc(outputFormat: OutputFormat) {
    switch (outputFormat) {
        case .Swift:
            fmt.println("TODO")
    }
}

newFrame :: proc(assetCount: int) -> ^Frame {
    frame := new(Frame)
    for _ in 0..<assetCount {
        append(&frame.placements, rl.Vector2{0, 0})
        append(&frame.rotations, 0)
    }
    return frame
}

loadSettings :: proc() -> Settings {
    return Settings{
        800,
        600,
    }
}

main :: proc() {
    // rl.SetWindowState(auto_cast rl.ConfigFlag.WINDOW_RESIZABLE)
    editor: Editor
    camera: rl.Camera2D
    // camera.target.x = 0
    // camera.target.y = 0
    // camera.offset.x = 0
    // camera.offset.y = 0
    // camera.zoom = 1
    settings := loadSettings()
    rl.SetTargetFPS(60)
	rl.InitWindow(settings.screenWidth, settings.screenHeight, "AnimPosition")
    placementTexture = rl.LoadTexture("Assets/placement.png")
    rotationTexture = rl.LoadTexture("Assets/rotation.png")

    defer rl.UnloadTexture(placementTexture)
    defer rl.UnloadTexture(rotationTexture)
    editor.activeTool = .MOVE
    editor.settings = &settings
    editor.camera = &camera
    append(&editor.frames, newFrame(len(editor.assets)));
    
    append(&editor.assets, NameAndTexture{name = "Placement", texture = &placementTexture})

	for !rl.WindowShouldClose() {
        render(&editor)
        input(&editor)
        update(&editor)
	}

	rl.CloseWindow()
}

toolBarWidth :: proc(editor: ^Editor) -> i32 {
    return editor.settings.screenWidth / 24
}

frameBarHeight :: proc(editor: ^Editor) -> i32 {
    return editor.settings.screenHeight / 4
}
 
renderToolbar :: proc(editor: ^Editor) {
    settings: ^Settings = editor.settings
    sidebarWidth := toolBarWidth(editor)

    toolWidth, toolHeight := sidebarWidth - 4, sidebarWidth - 4
    rectangle := rl.Rectangle{ x = auto_cast (settings.screenWidth - sidebarWidth), y = 0, width = auto_cast sidebarWidth, height = auto_cast (TOOL_COUNT * toolHeight + 6) } 
    x := rectangle.x + 2
    y: i32 = 2
    rl.DrawRectangle(auto_cast rectangle.x, auto_cast rectangle.y, auto_cast rectangle.width, auto_cast rectangle.height, rl.BLACK)
    for t in Tool {
        if t == editor.activeTool {
            rl.DrawRectangle(auto_cast x, auto_cast y, toolWidth, toolHeight, rl.WHITE)
        } else {
            rl.DrawRectangle(auto_cast x, auto_cast y, toolWidth, toolHeight, rl.GRAY)
        }
        drawTool(t, auto_cast x, auto_cast y)
        y += toolHeight + 2
    }
}

getToolTexture :: proc(tool: Tool) -> rl.Texture2D {
    switch tool {
        case .MOVE:
            return placementTexture
        case .ROTATE:
            return rotationTexture
        case:
            return rotationTexture
    }  
}

drawTool :: proc(tool: Tool, x: i32, y: i32) {
    texture := getToolTexture(tool)
    rl.DrawTexture(texture, auto_cast x, auto_cast y, rl.WHITE)
} 

renderFrameWindow :: proc(editor: ^Editor) {
    settings := editor.settings
    toolBarWidth := toolBarWidth(editor)
}

render :: proc(editor: ^Editor) {
	rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.GetMousePosition()
    rl.ClearBackground(rl.DARKPURPLE)    
    rl.BeginMode2D(editor.camera^)
    renderMainView(editor)
    rl.EndMode2D()
    renderToolbar(editor)
    renderFrameBar(editor)
}

renderFrameBar :: proc(editor: ^Editor) {
    frameBarHeight := frameBarHeight(editor)
    settings := editor.settings
    rl.DrawRectangle(0, settings.screenHeight - frameBarHeight, settings.screenWidth, frameBarHeight, rl.BLUE)

    X_OFFSET :: 12
    yOffset := 6 + settings.screenHeight - frameBarHeight 
    ROW_HEIGHT :: 16
    ROW_WIDTH :: 64

    // First block will write the frame number when going to left, therefore, add ROW_HEIGHT
    currentY := yOffset + ROW_HEIGHT
    for asset in editor.assets {
        rl.DrawRectangleLines(X_OFFSET, auto_cast currentY, ROW_WIDTH, ROW_HEIGHT, rl.WHITE)
        rl.DrawText(asset.name, X_OFFSET + 4, currentY + 2, 12, rl.WHITE)
        currentY := ROW_HEIGHT
    }

    currentY = yOffset
    builder := strings.make_builder()
    for frame, index in editor.frames {
        rl.DrawRectangleLines(auto_cast (X_OFFSET + ROW_WIDTH + ROW_WIDTH * index), auto_cast currentY, ROW_WIDTH, ROW_HEIGHT, rl.WHITE)
        strings.write_int(&builder, index + 1)
        rl.DrawText(strings.clone_to_cstring(strings.to_string(builder)), auto_cast (X_OFFSET + ROW_WIDTH * 1.5 + ROW_WIDTH * index), yOffset + 2, 12, rl.WHITE)
        strings.reset_builder(&builder)
    }
}

renderMainView :: proc(editor: ^Editor) {

}

input :: proc(editor: ^Editor) {
    if toolBarSelection(editor) do return
    if frameEditing(editor) do return
    rl.SetMouseOffset(auto_cast editor.camera.target.x, auto_cast editor.camera.target.y)

    rl.SetMouseOffset(0, 0)
}

toolBarSelection :: proc(editor: ^Editor) -> bool {
    if !rl.IsMouseButtonDown(rl.MouseButton.LEFT) do return false
    mousePosition := rl.GetMousePosition()
    settings := editor.settings
    sidebarWidth := toolBarWidth(editor) 
    toolWidth, toolHeight := sidebarWidth - 4, sidebarWidth - 4
    x := (settings.screenWidth - sidebarWidth) + 2
    y: i32 = 2

    for t in Tool {
        if rl.CheckCollisionPointRec(mousePosition, rl.Rectangle{
            x = auto_cast x,
            y = auto_cast y,
            width = auto_cast toolWidth,
            height = auto_cast toolHeight
        }) {
            editor.activeTool = t
            return true
        } 
        y += toolHeight + 2
    }
    return false
}

frameEditing :: proc(editor: ^Editor) -> bool {
    return false
}

update :: proc(editor: ^Editor) {

}