import json
import urllib.request

# Read token
with open('/home/hp/products/.gumroad_token') as f:
    TOKEN = f.read().strip()

# Check sales
try:
    req = urllib.request.Request('https://api.gumroad.com/v2/sales')
    req.add_header('Authorization', 'Bearer ' + TOKEN)
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
        sales = data.get('sales', [])
        total_revenue = sum(s.get('price', 0) for s in sales) / 100
        print('=== GUMROAD STATS ===')
        print('Total sales: ' + str(len(sales)))
        print('Total revenue: $' + str(total_revenue))
        
        if sales:
            print('\nRecent sales:')
            for s in sales[:5]:
                print('  - ' + s.get('product_name', 'Unknown') + ' ($' + str(s.get('price', 0)/100) + ')')
        else:
            print('\nNo sales yet - need more promotion!')
except Exception as e:
    print('Error checking sales: ' + str(e))

# Check products
try:
    req2 = urllib.request.Request('https://api.gumroad.com/v2/products')
    req2.add_header('Authorization', 'Bearer ' + TOKEN)
    with urllib.request.urlopen(req2) as resp2:
        data2 = json.loads(resp2.read())
        products = data2.get('products', [])
        print('\n=== PRODUCT VIEWS ===')
        for p in products:
            print('  - ' + p.get('name', 'Unknown') + ': ' + str(p.get('views_count', 0)) + ' views')
except Exception as e:
    print('Error checking products: ' + str(e))
