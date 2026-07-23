function d = binData(data, varargin)
%BINDATA  Bin a time series to a fixed rate or to arbitrary bin edges.
%
%   d = binData(data, binRate, sampleRate)
%       Uniform binning at binRate Hz over data acquired at sampleRate
%       Hz. Each output bin is the mean of data over one
%       binSize = sampleRate / binRate samples. Bit-for-bit compatible
%       with the legacy Symphony2 binData behaviour, including the
%       fractional-boundary rounding
%           idx = round(binSize*(k-1)) + 1 : round(binSize*k)
%       that keeps bins as close to (sampleRate/binRate) samples wide
%       as possible even when that ratio is non-integer.
%
%   d = binData(data, edges, sampleRate)
%       Edge-based binning: when the second argument is a VECTOR of
%       length > 1 it is treated as an ordered list of bin edges (in
%       sample indices at sampleRate — the same convention returned by
%       COMMON.UTIL.GETFRAMETIMING). Each output bin d(:, k) is the
%       mean of data over samples whose indices fall in
%       [edges(k), edges(k+1)). Bins with no samples come out as NaN
%       so a genuine zero-mean bin and an empty bin can be
%       distinguished downstream.
%
%   d = binData(data, 'edges', edges, 'sampleRate', sampleRate)
%   d = binData(data, 'binRate', binRate, 'sampleRate', sampleRate)
%       Explicit name-value forms. Useful when the caller wants the
%       intent to be obvious at the call site, or when they'd rather
%       not rely on the "vector means edges, scalar means rate"
%       positional overloading.
%
%   Inputs
%   ------
%     data        Row vector, column vector, or (nChannels x nSamples)
%                 matrix. Column vectors are transposed internally so
%                 the return shape is always (nChannels x nBins) with
%                 nChannels = 1 for vector input.
%     binRate     Scalar target bin rate in Hz.
%     edges       Vector of bin edges in SAMPLE INDICES at sampleRate.
%                 nBins = numel(edges) - 1. Edges are sorted
%                 defensively if not already ordered.
%     sampleRate  Scalar acquisition sample rate in Hz.
%
%   Output
%   ------
%     d           (nChannels x nBins) matrix of per-bin means.
%
%   Examples
%   --------
%     % Legacy uniform-rate call:
%     r = binData(voltageTrace, 60, 10000);   % rebin 10 kHz -> 60 Hz
%
%     % Edge-based call using frame timing:
%     [fT, ~] = common.util.getFrameTiming(frameMonitor, 1);
%     r      = binData(voltageTrace, fT, 10000);
%
%     % Explicit name-value form (recommended for new code):
%     r = binData(voltageTrace, 'edges', fT, 'sampleRate', 10000);
%
%   See also: common.util.getFrameTiming

    % --- Parse args (support positional and name-value forms) --------
    [mode, param2, sampleRate] = parse_args(varargin);

    % --- Normalise data shape to (nChannels x nSamples) --------------
    if isvector(data) && iscolumn(data)
        data = data.';
    end
    [nChan, N] = size(data);

    % --- Dispatch ----------------------------------------------------
    switch mode
        case 'rate'
            binRate = double(param2);
            if isempty(sampleRate)
                error('binData:missingSampleRate', ...
                    'Uniform-rate binning requires sampleRate.');
            end
            if binRate <= 0 || sampleRate <= 0
                error('binData:badRate', ...
                    'binRate and sampleRate must be positive.');
            end
            binSize = double(sampleRate) / binRate;
            nBins   = floor(N / binSize);
            d       = zeros(nChan, nBins);
            for k = 1 : nBins
                idx     = round(binSize*(k-1)) + 1 : round(binSize*k);
                d(:, k) = mean(data(:, idx), 2);
            end

        case 'edges'
            edges = double(param2(:)).';
            edges = sort(edges);          % defensive against unsorted input
            nBins = numel(edges) - 1;
            if nBins < 1
                error('binData:tooFewEdges', ...
                    'Edge-based binning requires at least 2 edges (got %d).', ...
                    numel(edges));
            end

            % Assign each sample to a bin. discretize returns NaN for
            % samples outside [edges(1), edges(end)).
            t_samp  = 1 : N;
            bin_idx = discretize(t_samp, edges);
            valid   = ~isnan(bin_idx);

            % Per-channel group mean; empty bins -> NaN.
            d = nan(nChan, nBins);
            for c = 1 : nChan
                d(c, :) = accumarray(bin_idx(valid).', ...
                                     double(data(c, valid)).', ...
                                     [nBins, 1], @mean, NaN).';
            end
    end
end


% =====================================================================
% Local helpers
% =====================================================================
function [mode, param2, sampleRate] = parse_args(args)
% Accepts three calling conventions:
%   binData(data, binRate,    sampleRate)     -- scalar binRate  -> 'rate'
%   binData(data, edges,      sampleRate)     -- vector edges    -> 'edges'
%   binData(data, 'edges',    edges,    ...
%                 'sampleRate', sampleRate)
%   binData(data, 'binRate',  binRate,  ...
%                 'sampleRate', sampleRate)
% Returns (mode, param2, sampleRate) where mode is 'rate' or 'edges'.

    if isempty(args)
        error('binData:notEnoughInputs', ...
              'binData requires at least two arguments.');
    end

    % --- Name-value form: first arg is a char/string identifier ------
    if ischar(args{1}) || isstring(args{1})
        ip = inputParser;
        ip.FunctionName = mfilename;
        ip.addParameter('edges',      [], ...
                        @(x) isnumeric(x) && (isvector(x) || isempty(x)));
        ip.addParameter('binRate',    [], ...
                        @(x) isnumeric(x) && isscalar(x));
        ip.addParameter('sampleRate', [], ...
                        @(x) isnumeric(x) && isscalar(x));
        ip.parse(args{:});
        opts       = ip.Results;
        sampleRate = opts.sampleRate;

        if ~isempty(opts.edges)
            mode   = 'edges';
            param2 = opts.edges;
        elseif ~isempty(opts.binRate)
            mode   = 'rate';
            param2 = opts.binRate;
        else
            error('binData:badArgs', ...
                'Must specify either ''edges'' or ''binRate''.');
        end
        return
    end

    % --- Positional form: (data, param2, sampleRate) ----------------
    if numel(args) < 2
        error('binData:notEnoughInputs', ...
              ['binData(data, X, sampleRate) requires 3 arguments ' ...
               'positionally.']);
    end
    param2     = args{1};
    sampleRate = args{2};

    if ~isnumeric(param2)
        error('binData:badArgs', ...
            'Second argument must be a numeric binRate (scalar) or edges (vector).');
    end
    if isscalar(param2)
        mode = 'rate';
    elseif isvector(param2) && numel(param2) > 1
        mode = 'edges';
    else
        error('binData:badArgs', ...
            ['Second argument must be either a scalar binRate or a ' ...
             'vector of edges with at least 2 elements.']);
    end
end
