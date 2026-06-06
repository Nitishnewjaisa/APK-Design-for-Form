/** Browser scroll manager for long multi-step forms. */
export class ScrollManager {
  constructor(page, { maxRetries = 8, delayMs = 600 } = {}) {
    this.page = page;
    this.maxRetries = maxRetries;
    this.delayMs = delayMs;
    this.scrollCount = 0;
  }

  async scrollDown() {
    await this.page.evaluate(() => {
      window.scrollBy(0, window.innerHeight * 0.6);
    });
    this.scrollCount++;
    await this.page.waitForTimeout(this.delayMs);
    return true;
  }

  async scrollToTop() {
    await this.page.evaluate(() => window.scrollTo(0, 0));
  }
}
