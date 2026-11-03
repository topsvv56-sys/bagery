const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const DB_FILE = path.join(__dirname, 'bakery_data.json');

// ຂໍ້ມູນເລີ່ມຕົ້ນ (ພາສາລາວ)
const defaultData = {
  products: [
    {
      id: 1,
      name: "ຄົວຊອງເນີຍສົດ",
      category: "ເຂົ້າໜົມປັງ",
      price: 25000,
      image: "assets/images/croissant.jpg",
      description: "ຄົວຊອງອົບໃໝ່ທຸກເຊົ້າ ໃຊ້ເນີຍສົດແທ້ຈາກຝຣັ່ງ ກອບນອກນຸ້ມໃນ ຫອມເນີຍທຸກຄຳ",
      stock: 30
    },
    {
      id: 2,
      name: "ເຄັກຊັອກໂກແລັດເຂັ້ມຂຸ້ນ",
      category: "ເຄັກ",
      price: 45000,
      image: "assets/images/chocolate_cake.jpg",
      description: "ເຄັກຊັອກໂກແລັດເນື້ອແໜ້ນ ລາດດ້ວຍການາສດາກຊັອກໂກແລັດ 70% ເຂັ້ມຂຸ້ນເຖິງໃຈ",
      stock: 15
    },
    {
      id: 3,
      name: "ບາແກັດຝຣັ່ງ",
      category: "ເຂົ້າໜົມປັງ",
      price: 35000,
      image: "assets/images/baguette.jpg",
      description: "ເຂົ້າໜົມປັງບາແກັດເປືອກກອບ ເນື້ອໜຽວນຸ້ມ ເໝາະເຮັດແຊນວິດ ຫຼື ກິນກັບແກງ",
      stock: 20
    },
    {
      id: 4,
      name: "ໂດນັດສະຕໍເບີຣີ",
      category: "ເຂົ້າໜົມຫວານ",
      price: 20000,
      image: "assets/images/donut.jpg",
      description: "ໂດນັດເນື້ອນຸ້ມຟູ ເຄືອບໄອຊິງສະຕໍເບີຣີສີບົວ ໂຣຍເມັດນ້ຳຕານສີສັນສົດໃສ",
      stock: 40
    },
    {
      id: 5,
      name: "ຊິນນາມອນໂຣລ",
      category: "ເຂົ້າໜົມປັງ",
      price: 30000,
      image: "assets/images/cinnamon_roll.jpg",
      description: "ເຂົ້າໜົມປັງມ້ວນອົບເຊີຍ ຫອມກຸ່ນ ລາດຄຣີມຊີສໄອຊິງ ກິນຄູ່ກາເຟແຊບຫຼາຍ",
      stock: 25
    },
    {
      id: 6,
      name: "ສະຕໍເບີຣີຊອດເຄັກ",
      category: "ເຄັກ",
      price: 55000,
      image: "assets/images/strawberry_cake.jpg",
      description: "ເຄັກສະປັນຈ໌ນຸ້ມເບົາ ສະຫຼັບຊັ້ນວິບຄຣີມສົດ ແລະ ສະຕໍເບີຣີສົດຫວານອົມສົ້ມ",
      stock: 12
    },
    {
      id: 7,
      name: "ຊູຄຣີມວານິລາ",
      category: "ເຂົ້າໜົມຫວານ",
      price: 15000,
      image: "assets/images/cream_puff.jpg",
      description: "ແປ້ງຊູກອບເບົາ ສອດໄສ້ຄັສຕາດວານິລາແທ້ເຕັມຄຳ ຫວານພໍດີ",
      stock: 50
    },
    {
      id: 8,
      name: "ເມລອນປັງ",
      category: "ເຂົ້າໜົມປັງ",
      price: 22000,
      image: "assets/images/melon_pan.jpg",
      description: "ເຂົ້າໜົມປັງສະໄຕລ໌ຍີ່ປຸ່ນ ຜິວຄຸກກີ້ກອບຫວານ ເນື້ອໃນນຸ້ມຟູຫອມນົມ",
      stock: 35
    }
  ],
  customers: [
    {
      id: 1,
      name: "ສົມໄຊ ໃຈດີ",
      phone: "020 55556789",
      address: "ບ້ານໂພນສີນວນ, ເມືອງສີສັດຕະນາກ, ນະຄອນຫຼວງວຽງຈັນ",
      note: "ມັກຄົວຊອງກອບໆ",
      created_at: new Date().toISOString()
    },
    {
      id: 2,
      name: "ດາວວອນ ສົດໃສ",
      phone: "020 99887766",
      address: "ບ້านດົງໂດກ, ເມືອງໄຊທານີ, ນະຄອນຫຼວງວຽງຈັນ",
      note: "ບໍ່ຫວານຫຼາຍ",
      created_at: new Date().toISOString()
    }
  ],
  orders: [
    {
      id: 1,
      customer_id: 1,
      customer_name: "ສົມໄຊ ໃຈດີ",
      total: 72000,
      created_at: new Date().toISOString(),
      items: [
        { product_id: 1, product_name: "ຄົວຊອງເນີຍສົດ", price: 25000, quantity: 2 },
        { product_id: 8, product_name: "ເມລອນປັງ", price: 22000, quantity: 1 }
      ]
    }
  ]
};

// ອ່ານຂໍ້ມູນ
function readDb() {
  if (!fs.existsSync(DB_FILE)) {
    fs.writeFileSync(DB_FILE, JSON.stringify(defaultData, null, 2), 'utf-8');
    return defaultData;
  }
  try {
    const raw = fs.readFileSync(DB_FILE, 'utf-8');
    return JSON.parse(raw);
  } catch (err) {
    return defaultData;
  }
}

// ບັນທຶກຂໍ້ມູນ
function writeDb(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
}

// ---------------- API Endpoints ---------------- //

app.get('/', (req, res) => {
  res.json({
    message: "Sweet Crumb Bakery API Server (ພາສາລາວ)",
    status: "running",
    endpoints: [
      "GET /api/products",
      "GET /api/products/:id",
      "GET /api/customers",
      "POST /api/customers",
      "GET /api/orders",
      "POST /api/orders"
    ]
  });
});

// 1. ດຶງສິນຄ້າທັງໝົດ ຫຼື ຄົ້ນຫາ (?search= ຫຼື ?category=)
app.get('/api/products', (req, res) => {
  const db = readDb();
  let list = db.products || [];
  const { search, category } = req.query;

  if (category && category !== 'ທັງໝົດ') {
    list = list.filter(p => p.category === category);
  }

  if (search) {
    const q = search.toLowerCase();
    list = list.filter(p => 
      p.name.toLowerCase().includes(q) ||
      p.category.toLowerCase().includes(q) ||
      (p.description && p.description.toLowerCase().includes(q))
    );
  }

  res.json({
    total: list.length,
    data: list
  });
});

// 2. ດຶງສິນຄ້າຕາມ ID
app.get('/api/products/:id', (req, res) => {
  const db = readDb();
  const product = db.products.find(p => p.id === parseInt(req.params.id));
  if (!product) {
    return res.status(404).json({ error: "ບໍ່ພົບສິນຄ້ານີ້" });
  }
  res.json({ data: product });
});

// 3. ດຶງລາຍຊື່ລູກຄ້າທັງໝົດ ຫຼື ຄົ້ນຫາ (?search=)
app.get('/api/customers', (req, res) => {
  const db = readDb();
  let list = db.customers || [];
  const { search } = req.query;

  if (search) {
    const q = search.toLowerCase();
    list = list.filter(c =>
      c.name.toLowerCase().includes(q) ||
      (c.phone && c.phone.includes(q)) ||
      (c.address && c.address.toLowerCase().includes(q))
    );
  }

  const customersWithStats = list.map(c => {
    const userOrders = (db.orders || []).filter(o => o.customer_id === c.id);
    const orderCount = userOrders.length;
    const totalSpent = userOrders.reduce((sum, o) => sum + (o.total || 0), 0);
    return {
      ...c,
      order_count: orderCount,
      total_spent: totalSpent
    };
  });

  res.json({
    total: customersWithStats.length,
    data: customersWithStats
  });
});

// 4. ເພີ່ມລູກຄ້າໃໝ່
app.post('/api/customers', (req, res) => {
  const { name, phone, address, note } = req.body;
  if (!name || !name.trim()) {
    return res.status(400).json({ error: "ກະລຸນາໃສ່ຊື່ລູກຄ້າ" });
  }

  const db = readDb();
  const nextId = db.customers.length > 0 ? Math.max(...db.customers.map(c => c.id)) + 1 : 1;
  const newCustomer = {
    id: nextId,
    name: name.trim(),
    phone: (phone || '').trim(),
    address: (address || '').trim(),
    note: (note || '').trim(),
    created_at: new Date().toISOString()
  };

  db.customers.push(newCustomer);
  writeDb(db);

  res.status(201).json({
    message: "ບັນທຶກຂໍ້ມູນລູກຄ້າສຳເລັດ",
    data: newCustomer
  });
});

// 5. ດຶງລາຍການສັ່ງຊື້ທັງໝົດ
app.get('/api/orders', (req, res) => {
  const db = readDb();
  res.json({
    total: (db.orders || []).length,
    data: (db.orders || []).slice().reverse()
  });
});

// 6. ສ້າງຄຳສັ່ງຊື້ໃໝ່ (ພ້ອມຕັດສະຕັອກສິນຄ້າ)
app.post('/api/orders', (req, res) => {
  const { customer_id, items } = req.body;
  if (!customer_id) {
    return res.status(400).json({ error: "ກະລຸນາໃສ່ customer_id" });
  }
  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: "ກະລຸນາໃສ່ລາຍການສິນຄ້າໃນ items" });
  }

  const db = readDb();
  const customer = db.customers.find(c => c.id === parseInt(customer_id));
  if (!customer) {
    return res.status(404).json({ error: "ບໍ່ພົບລະຫັດລູກຄ້ານີ້" });
  }

  let total = 0;
  const orderItems = [];

  for (const item of items) {
    const product = db.products.find(p => p.id === parseInt(item.product_id));
    if (!product) {
      return res.status(400).json({ error: `ບໍ່ພົບລະຫັດສິນຄ້າ ${item.product_id}` });
    }
    const qty = parseInt(item.quantity) || 1;
    if (product.stock < qty) {
      return res.status(400).json({ error: `ສິນຄ້າ ${product.name} ມີສະຕັອກບໍ່ພໍ (ຍັງເຫຼືອ ${product.stock})` });
    }

    product.stock -= qty;

    const subtotal = product.price * qty;
    total += subtotal;

    orderItems.push({
      product_id: product.id,
      product_name: product.name,
      price: product.price,
      quantity: qty
    });
  }

  const nextOrderId = db.orders.length > 0 ? Math.max(...db.orders.map(o => o.id)) + 1 : 1;
  const newOrder = {
    id: nextOrderId,
    customer_id: customer.id,
    customer_name: customer.name,
    total: total,
    created_at: new Date().toISOString(),
    items: orderItems
  };

  db.orders.push(newOrder);
  writeDb(db);

  res.status(201).json({
    message: "ບັນທຶກຄຳສັ່ງຊື້ສຳເລັດ",
    data: newOrder
  });
});

app.listen(PORT, () => {
  console.log(`Bakery API Server is running on http://localhost:${PORT}`);
});
