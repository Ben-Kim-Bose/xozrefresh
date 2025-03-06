using GLMakie, ControlSystems, DSP
GLMakie.activate!()
GLMakie.closeall()

mutable struct mBQ
    K::ControlSystems.TransferFunction
    F::Vector{Float64}
    Rmag::Vector{Float64}
    Rpha::Vector{Float64}
end

fs = Observable(48000.0);
w = exp10.(LinRange(0, ceil(log10(fs[]/2)), 1800));
defaultcoefs = [1.0; 0.0; 0.0; 0.0; 0.0]
b0 = Observable(defaultcoefs[1]);
b1 = Observable(defaultcoefs[2]);
b2 = Observable(defaultcoefs[3]);
a1 = Observable(defaultcoefs[4]);
a2 = Observable(defaultcoefs[5]);

soscoefs = @lift([$b0; $b1; $b2; $a1; $a2]);

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

function init_BQstruct(coefs::Observable)
    H = tf(ZeroPoleGain(Biquad(coefs[]...)), 1/fs[]);
    mag, pha, ~ = bodev(H, w; unwrap=true);
    return mBQ(H, w, 20*log10.(mag), pha)
end

## Define Figure
fig = Figure(size = (1200, 600))

## Bode Plot GridLayout
subgl_bode = GridLayout();
subgl_bode[1:2, 1] = [Axis(fig) for i in 1:2];
bodeax = [b.content for b in subgl_bode.content];
set_bode_ax(bodeax);

subgl_menu = GridLayout();
subgl_menu[1,1:5] = [Textbox(
        fig, 
        placeholder=repr(soscoefs[][i]), 
        stored_string=repr(soscoefs[][i]),
        tellheight=false,
        valign=:top,
        width=50
    ) for i in 1:5]

menutb = [t.content for t in subgl_menu.content]
# menutb[1].stored_string

for (i, coef) in enumerate([b0, b1, b2, a1, a2])
    on(menutb[i].stored_string) do s
        coef[] = parse(Float64, s)
    end
end


lines!(bodeax[1], w, init_BQstruct(@lift([$b0; $b1; $b2; $a1; $a2])).Rmag);
lines!(bodeax[2], w, init_BQstruct(@lift([$b0; $b1; $b2; $a1; $a2])).Rpha);
ylims!(bodeax[1], -30, 10)
ylims!(bodeax[2], -180, 180)

fig.layout[1,1] = subgl_bode;
fig.layout[1,2] = subgl_menu;

fig
