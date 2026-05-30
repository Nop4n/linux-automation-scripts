const { chromium } = require('playwright');

async function searchStackOverflow() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  // Search Stack Overflow for recent Linux questions
  const queries = [
    'linux server setup',
    'nginx configuration help',
    'docker compose linux',
    'linux security hardening',
    'bash script automation'
  ];
  
  const results = [];
  
  for (const query of queries) {
    try {
      await page.goto(`https://stackoverflow.com/search?q=${encodeURIComponent(query)}&tab=newest`, {
        waitUntil: 'domcontentloaded',
        timeout: 30000
      });
      
      await page.waitForTimeout(2000);
      
      const posts = await page.evaluate(() => {
        const items = [];
        const postElements = document.querySelectorAll('.question-summary');
        postElements.forEach((el, i) => {
          if (i < 3) {
            const titleEl = el.querySelector('.question-hyperlink');
            const statsEl = el.querySelector('.status');
            items.push({
              title: titleEl?.textContent?.trim() || '',
              url: titleEl?.href || '',
              votes: statsEl?.textContent?.trim() || ''
            });
          }
        });
        return items;
      });
      
      results.push({ query, posts });
      console.log(`✓ Found ${posts.length} posts for: ${query}`);
    } catch (e) {
      console.log(`✗ Error for ${query}: ${e.message}`);
    }
  }
  
  await browser.close();
  
  const fs = require('fs');
  fs.writeFileSync('/home/hp/products/so-leads.json', JSON.stringify(results, null, 2));
  console.log('\nResults saved to /home/hp/products/so-leads.json');
}

searchStackOverflow().catch(console.error);
