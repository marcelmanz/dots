// Base URL of the API
const BASE_URL = "http://localhost:8081/api/device/data";

// Array of all values to be sent
const dataPoints = [
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 30, hrt: 0 },
    ts: Date.now() - 7 * 60 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 30, bp_dia: 20 },
    ts: Date.now() - 7 * 60 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 30, hrt: 0 },
    ts: Date.now() - 5 * 60 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 30, bp_dia: 20 },
    ts: Date.now() - 5 * 60 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 32, bp_dia: 22 },
    ts: Date.now() - 4 * 60 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 36, bp_dia: 24 },
    ts: Date.now() - 3 * 60 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 38, bp_dia: 25 },
    ts: Date.now() - 2 * 60 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 36, bp_dia: 24 },
    ts: Date.now() - 1 * 60 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 32, bp_dia: 22 },
    ts: Date.now(),
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 30, bp_dia: 20 },
    ts: Date.now() + 1 * 60 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 32, hrt: 5 },
    ts: Date.now() + 1 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 36, hrt: 5 },
    ts: Date.now() + 2 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 39, hrt: 5 },
    ts: Date.now() + 3 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 36, hrt: 0 },
    ts: Date.now() + 4 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 32, hrt: 0 },
    ts: Date.now() + 5 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 30, bp_dia: 20 },
    ts: Date.now() + 6 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 30, hrt: 0 },
    ts: Date.now() + 6 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "44444444-4444-4444-4444-444444444444",
    model: "BPA",
    version: "1.3",
    payload: { bp_sys: 30, bp_dia: 20 },
    ts: Date.now() + 8 * 60 * 1000 + 30 * 1000,
  },
  {
    eui: "33333333-3333-3333-3333-333333333333",
    model: "X1-S",
    version: "1.1",
    payload: { hr: 30, hrt: 0 },
    ts: Date.now() + 8 * 60 * 1000 + 30 * 1000,
  },
];

// Function to send request
const sendRequest = async (data: any) => {
  try {
    const formattedTs = new Date(data.ts).toLocaleTimeString();
    console.log(`\n> Sending request with timestamp ${formattedTs}`);
    console.log(data);
    const response = await fetch(BASE_URL, {
      headers: { "Content-Type": "application/json" },
    });
    console.log("Response:", response.json());
  } catch (error) {
    console.error("Error sending request:", error);
  }
};

// Iterate over data points and send each one
(async () => {
  for (const data of dataPoints) {
    await sendRequest(data);
  }
  console.log("\nAll requests sent!");
})();
