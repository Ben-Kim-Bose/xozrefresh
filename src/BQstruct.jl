module BQstruct
using ControlSystems
export BQ, getfr

mutable struct BQ
    K::ControlSystems.TransferFunction
    freqvec::Vector{Float64}
end

function getfr(bq::BQ)
    mag, pha, ~ = bodev(bq.K, bq.freqvec; unwrap=false);
    return 20*log10.(mag), pha
end

end # MODULE

using .BQstruct, ControlSystems, DSP
fs = 48000.0
w = exp10.(LinRange(0, ceil(log10(fs/2)), 501));
H = tf(digitalfilter(Lowpass(3000.0), Butterworth(2); fs=fs), 1/fs);
mybq = BQ(H, w);
Hmag, Hpha = getfr(mybq);