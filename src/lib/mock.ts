/** Simulate the latency of the real integration so the frontend sees realistic timing. */
export const delay = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));
