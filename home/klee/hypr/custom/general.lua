-- Custom general configurations for VRR and Direct Scanout
hl.config({
    misc = {
        -- 显示器上报 Vrr: incapable；先关闭，避免 NVIDIA 下异常
        vrr = 0,
    },
    render = {
        direct_scanout = false, -- 关闭直通渲染，防止混合合成模式下画面闪烁
    }
})
