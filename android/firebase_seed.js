const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Real charging stations in Malaysia with accurate coordinates
const chargingStations = [
  {
    name: "ChargEV - Pavilion KL",
    location: new admin.firestore.GeoPoint(3.1490, 101.7137),
    address: "Pavilion Kuala Lumpur Shopping Centre, Bukit Bintang",
    availableChargers: 4,
    totalChargers: 6,
    chargerType: "AC Charge",
    pricePerKwh: 0.80,
    operator: "ChargEV",
    amenities: ["Shopping Mall", "Food Court", "Cinema", "Parking"],
    distance: 2.5,
    estimatedTime: 5,
    reachable: true,
    energyRequired: 3
  },
  {
    name: "Gentari - Petronas KLCC",
    location: new admin.firestore.GeoPoint(3.1578, 101.7123),
    address: "PETRONAS Twin Towers, KLCC",
    availableChargers: 3,
    totalChargers: 4,
    chargerType: "DC Fast",
    pricePerKwh: 1.20,
    operator: "Gentari",
    amenities: ["Shopping Mall", "Convention Center", "Park"],
    distance: 3.2,
    estimatedTime: 6,
    reachable: true,
    energyRequired: 4
  },
  {
    name: "Shell Recharge - Mid Valley",
    location: new admin.firestore.GeoPoint(3.1185, 101.6773),
    address: "Mid Valley Megamall, Lingkaran Syed Putra",
    availableChargers: 2,
    totalChargers: 3,
    chargerType: "DC Fast",
    pricePerKwh: 1.15,
    operator: "Shell",
    amenities: ["Shopping Mall", "Food Court", "Cinema"],
    distance: 5.8,
    estimatedTime: 10,
    reachable: true,
    energyRequired: 6
  },
  {
    name: "TNB EV - Sunway Pyramid",
    location: new admin.firestore.GeoPoint(3.0738, 101.6067),
    address: "Sunway Pyramid Shopping Mall, Bandar Sunway",
    availableChargers: 3,
    totalChargers: 4,
    chargerType: "AC Charge",
    pricePerKwh: 0.75,
    operator: "TNB",
    amenities: ["Shopping Mall", "Ice Skating", "Theme Park"],
    distance: 12.5,
    estimatedTime: 18,
    reachable: true,
    energyRequired: 12
  },
  {
    name: "ChargEV - 1 Utama",
    location: new admin.firestore.GeoPoint(3.1497, 101.6147),
    address: "1 Utama Shopping Centre, Bandar Utama",
    availableChargers: 5,
    totalChargers: 8,
    chargerType: "AC Charge",
    pricePerKwh: 0.70,
    operator: "ChargEV",
    amenities: ["Shopping Mall", "Food Court", "Rooftop Garden"],
    distance: 8.3,
    estimatedTime: 12,
    reachable: true,
    energyRequired: 8
  },
  {
    name: "JomCharge - IOI City Mall",
    location: new admin.firestore.GeoPoint(2.9926, 101.7245),
    address: "IOI City Mall, Putrajaya",
    availableChargers: 2,
    totalChargers: 4,
    chargerType: "DC Fast",
    pricePerKwh: 1.10,
    operator: "JomCharge",
    amenities: ["Shopping Mall", "Ice Skating", "Cinema"],
    distance: 18.7,
    estimatedTime: 25,
    reachable: true,
    energyRequired: 18
  },
  {
    name: "Gentari - KLIA Gateway",
    location: new admin.firestore.GeoPoint(2.7456, 101.7072),
    address: "KLIA Gateway, Sepang",
    availableChargers: 1,
    totalChargers: 4,
    chargerType: "DC Fast",
    pricePerKwh: 1.25,
    operator: "Gentari",
    amenities: ["Airport Access", "Convenience Store"],
    distance: 45.3,
    estimatedTime: 55,
    reachable: false,
    energyRequired: 45
  },
  {
    name: "Shell Recharge - The Mines",
    location: new admin.firestore.GeoPoint(3.0332, 101.7185),
    address: "The Mines Shopping Mall, Seri Kembangan",
    availableChargers: 1,
    totalChargers: 2,
    chargerType: "AC Charge",
    pricePerKwh: 0.85,
    operator: "Shell",
    amenities: ["Shopping Mall", "Hotel", "Theme Park"],
    distance: 15.2,
    estimatedTime: 20,
    reachable: true,
    energyRequired: 14
  }
];

async function clearAndSeedData() {
  try {
    console.log('Clearing existing charging stations...');
    console.log('===========================================');
    
    // Delete existing stations
    const existingStations = await db.collection('charging_stations').get();
    const deletePromises = existingStations.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    console.log(`✓ Deleted ${existingStations.size} existing stations`);
    console.log('===========================================');
    
    console.log('Starting to seed charging stations...');
    console.log('===========================================');
    
    for (const station of chargingStations) {
      const docRef = await db.collection('charging_stations').add(station);
      console.log(`✓ Added: ${station.name}`);
      console.log(`  ID: ${docRef.id}`);
      console.log(`  Location: ${station.location.latitude}, ${station.location.longitude}`);
      console.log(`  Distance: ${station.distance} km`);
      console.log('-------------------------------------------');
    }
    
    console.log('===========================================');
    console.log('✓ Seeding completed successfully!');
    console.log(`Total stations added: ${chargingStations.length}`);
    process.exit(0);
  } catch (error) {
    console.error('✗ Error seeding data:', error);
    process.exit(1);
  }
}

clearAndSeedData();