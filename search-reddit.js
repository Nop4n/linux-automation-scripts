const { chromium } = require('playwright');

async function searchReddit() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  // Search Reddit for people asking for Linux help
  const queries = [
    'linux server setup help',
    'linux slow performance',
    'docker install linux',
    'linux security hardening',
    'backup script linux'
  ];
  
  const results = [];
  
  for (const query of queries) {
    try {
      await page.goto(`https://www.reddit.com/search/?q=${encodeURIComponent(query)}&sort=new&t=week`, {
        waitUntil: 'networkidle',
        timeout: 30000
      });
      
      // Wait for content to load
      await page.waitForTimeout(3000);
      
      // Get post titles and links
      const posts = await page.evaluate(() => {
        const items = [];
        const postElements = document.querySelectorAll('a[data-click-id="body"]');
        postElements.forEach((el, i) => {
          if (i < 5) { // Get first 5 posts
            items.push({
              title: el.textContent?.trim() || '',
              url: el.href || ''
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
  
  // Save results
  const fs = require('fs');
  fs.writeFileSync('/home/hp/products/reddit-leads.json', JSON.stringify(results, null, 2));
  console.log('\nResults saved to /home/hp/products/reddit-leads.json');
}

searchReddit().catch(console.error);
