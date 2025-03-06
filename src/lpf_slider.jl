using GLMakie, ControlSystems, DSP
GLMakie.activate!()
GLMakie.closeall()

mutable struct mLPF
    K::ControlSystems.TransferFunction
    F::Vector{Float64}
    Rmag::Vector{Float64}
    Rpha::Vector{Float64}
end

fs = Observable(48000.0);
fc = Observable(1000.0);
w = exp10.(LinRange(-1, ceil(log10(fs[]/2)), 1800));

function set_bode_ax(bodeax)
    for b in bodeax
        xlims!(b, w[1], w[end])
        b.xminorticksvisible = true;
        b.xminorgridvisible = true;
        b.xminorticks = IntervalsBetween(10)
        b.xscale = log10;
    end
    linkxaxes!(bodeax[1], bodeax[2])
    bodeax[1].ylabel = "Magnitude (dB)";  
    bodeax[2].ylabel = "Phase (degrees)";
    bodeax[2].xlabel = "Frequency (Hz)"; 
end

function init_LPF(fc::Float64)
    H = tf(digitalfilter(Lowpass(fc), Butterworth(2);fs=fs[]), 1/fs[]);
    mag, pha, ~ = bodev(H, w; unwrap=true);
    return mLPF(H, w, 20*log10.(mag), pha)
end

fig = Figure(size = (1200, 600))

## Bode Plot GridLayout
subgl_bode = GridLayout();
subgl_bode[1:2, 1] = [Axis(fig) for i in 1:2];
bodeax = [b.content for b in subgl_bode.content];
set_bode_ax(bodeax);

sg = SliderGrid(
    fig[1, 2],
    (label = "Frequency", range = 2*exp10.(-1:0.1:5), format = "{:.1f} Hz", startvalue = fc[]),
    width = 350,
    tellheight = false)

sliderobservables = [s.value for s in sg.sliders]
connect!(fc, sg.sliders[1].value)

lines!(bodeax[1], w, @lift(init_LPF($fc).Rmag));
lines!(bodeax[2], w, @lift(init_LPF($fc).Rpha));
vlines!(bodeax[1], @lift($fc/1))
ylims!(bodeax[1], -30, 10)
ylims!(bodeax[2], -180, 180)

fig.layout[1,1] = subgl_bode;

fig