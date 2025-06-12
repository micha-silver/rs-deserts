//VERSION=3
function setup() {
  return {
    input: [{
      bands: ["B02", "B03", "B04", "dataMask"]
    }],
    output: {
      bands: 4,
      sampleType: "UINT8"
    }
  };
}

function stretch(val, min, max) {
  return Math.min(255, Math.max(0, Math.round(255 * (val - min) / (max - min))));
}

function evaluatePixel(sample) {
  return [
    stretch(sample.B04, 0.01, 0.15), // Red
    stretch(sample.B03, 0.01, 0.15), // Green
    stretch(sample.B02, 0.01, 0.15), // Blue
    sample.dataMask * 255            // Alpha
  ];
}