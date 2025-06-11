//VERSION=3
function setup() {
  return {
    input: [{
      bands: ["B02", "B03", "B04", "dataMask"]
    }],
    output: {
      bands: 4,
      sampleType: "UINT8" // Force 0–255 range
    }
  };
}

function evaluatePixel(sample) {
  function stretch(val) {
    return Math.min(255, Math.max(0, Math.round(val * 255)));
  }

  return [
    stretch(sample.B04),  // Red
    stretch(sample.B03),  // Green
    stretch(sample.B02),  // Blue
    sample.dataMask * 255 // Alpha (0 or 255)
  ];
}
