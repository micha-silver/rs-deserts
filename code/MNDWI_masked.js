//VERSION=3
//MNDVI as unsigned FLOAT32

function setup() {
    return {
        input: [{ // this sets which bands to use
            bands: ["B03", "B11", "SCL"]
            }],
        output: { // this defines the output image type
            bands: 1,
            sampleType: "FLOAT32"
        }
    };
}

function evaluatePixel(sample) {
  // this computes the NDVI value
    let mndvi = (sample.B03 - sample.B11) / (sample.B03 + sample.B11);
    if ([2, 4, 5, 6, 7, 10].includes(sample.SCL)) {
      // Allow all veg, soil, water. Mask out all cloud, cloud shadow, snow
      return [ mndvi ];
    } else {
      return [NaN];
    };
}

