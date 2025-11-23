const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const vehicles = [
  {
    model: 'Tesla Model 3',
    manufacturer: 'Tesla',
    batteryCapacity: 60, // kWh
    range: 491, // km (WLTP)
    efficiency: 14.3, // kWh/100km
    chargingSpeed: {
      ac: 11, // kW
      dc: 170 // kW
    },
    acceleration: 6.1, // 0-100 km/h in seconds
    topSpeed: 225, // km/h
    imageUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800',
    year: 2024,
  },
  {
    model: 'BYD Atto 3',
    manufacturer: 'BYD',
    batteryCapacity: 60.48, // kWh
    range: 480, // km (WLTP)
    efficiency: 14.9, // kWh/100km
    chargingSpeed: {
      ac: 7, // kW
      dc: 80 // kW
    },
    acceleration: 7.3, // 0-100 km/h in seconds
    topSpeed: 160, // km/h
    imageUrl: 'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=800',
    year: 2024,
  },
  {
    model: 'BMW iX3',
    manufacturer: 'BMW',
    batteryCapacity: 80, // kWh
    range: 460, // km (WLTP)
    efficiency: 17.8, // kWh/100km
    chargingSpeed: {
      ac: 11, // kW
      dc: 150 // kW
    },
    acceleration: 6.8, // 0-100 km/h in seconds
    topSpeed: 180, // km/h
    imageUrl: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?w=800',
    year: 2024,
  },
  {
    model: 'Nissan Leaf',
    manufacturer: 'Nissan',
    batteryCapacity: 40, // kWh
    range: 270, // km (WLTP)
    efficiency: 17.0, // kWh/100km
    chargingSpeed: {
      ac: 6.6, // kW
      dc: 50 // kW
    },
    acceleration: 7.9, // 0-100 km/h in seconds
    topSpeed: 144, // km/h
    imageUrl: 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800',
    year: 2024,
  },
  {
    model: 'Hyundai Ioniq 5',
    manufacturer: 'Hyundai',
    batteryCapacity: 72.6, // kWh
    range: 481, // km (WLTP)
    efficiency: 16.7, // kWh/100km
    chargingSpeed: {
      ac: 11, // kW
      dc: 220 // kW (800V architecture)
    },
    acceleration: 7.4, // 0-100 km/h in seconds
    topSpeed: 185, // km/h
    imageUrl: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
    year: 2024,
  }
];

async function seedVehicles() {
  try {
    console.log('Starting to seed vehicle data...');
    console.log('===========================================');
    
    // Clear existing vehicles
    const existingVehicles = await db.collection('vehicles').get();
    const deletePromises = existingVehicles.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    console.log(`✓ Deleted ${existingVehicles.size} existing vehicles`);
    console.log('===========================================');
    
    for (const vehicle of vehicles) {
      const docRef = await db.collection('vehicles').add(vehicle);
      console.log(`✓ Added: ${vehicle.manufacturer} ${vehicle.model}`);
      console.log(`  Battery: ${vehicle.batteryCapacity} kWh`);
      console.log(`  Range: ${vehicle.range} km`);
      console.log(`  Efficiency: ${vehicle.efficiency} kWh/100km`);
      console.log('-------------------------------------------');
    }
    
    console.log('===========================================');
    console.log('✓ Vehicle seeding completed successfully!');
    console.log(`Total vehicles added: ${vehicles.length}`);
    process.exit(0);
  } catch (error) {
    console.error('✗ Error seeding vehicles:', error);
    process.exit(1);
  }
}

seedVehicles();