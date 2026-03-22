import type { Location } from '@islamic-day-dial/core';

export const MY_LOCATION_ID = 'automatic';
export const MY_LOCATION_TITLE = 'My location';

export type LocationPreset = {
  id: string;
  title: string;
  location: Location;
  timezone: string;
  utcOffsetHours: number;
};

/**
 * Cities: Muslim capitals + major cities with large Muslim populations.
 * User-provided list, duplicates removed. Sorted by UTC offset.
 */
const RAW_PRESETS: Omit<LocationPreset, 'utcOffsetHours'>[] = [
  { id: 'riyadh', title: 'Riyadh', location: { latitude: 24.7136, longitude: 46.6753 }, timezone: 'Asia/Riyadh' },
  { id: 'abu-dhabi', title: 'Abu Dhabi', location: { latitude: 24.4539, longitude: 54.3773 }, timezone: 'Asia/Dubai' },
  { id: 'doha', title: 'Doha', location: { latitude: 25.2854, longitude: 51.5310 }, timezone: 'Asia/Qatar' },
  { id: 'manama', title: 'Manama', location: { latitude: 26.2285, longitude: 50.5860 }, timezone: 'Asia/Bahrain' },
  { id: 'kuwait-city', title: 'Kuwait City', location: { latitude: 29.3759, longitude: 47.9774 }, timezone: 'Asia/Kuwait' },
  { id: 'muscat', title: 'Muscat', location: { latitude: 23.5880, longitude: 58.3829 }, timezone: 'Asia/Muscat' },
  { id: 'sanaa', title: "Sana'a", location: { latitude: 15.3694, longitude: 44.1910 }, timezone: 'Asia/Aden' },
  { id: 'baghdad', title: 'Baghdad', location: { latitude: 33.3152, longitude: 44.3661 }, timezone: 'Asia/Baghdad' },
  { id: 'damascus', title: 'Damascus', location: { latitude: 33.5138, longitude: 36.2765 }, timezone: 'Asia/Damascus' },
  { id: 'beirut', title: 'Beirut', location: { latitude: 33.8938, longitude: 35.5018 }, timezone: 'Asia/Beirut' },
  { id: 'amman', title: 'Amman', location: { latitude: 31.9454, longitude: 35.9284 }, timezone: 'Asia/Amman' },
  { id: 'jerusalem', title: 'Jerusalem', location: { latitude: 31.7683, longitude: 35.2137 }, timezone: 'Asia/Jerusalem' },
  { id: 'tehran', title: 'Tehran', location: { latitude: 35.6892, longitude: 51.3890 }, timezone: 'Asia/Tehran' },
  { id: 'cairo', title: 'Cairo', location: { latitude: 30.0444, longitude: 31.2357 }, timezone: 'Africa/Cairo' },
  { id: 'tripoli', title: 'Tripoli', location: { latitude: 32.8872, longitude: 13.1913 }, timezone: 'Africa/Tripoli' },
  { id: 'tunis', title: 'Tunis', location: { latitude: 36.8065, longitude: 10.1815 }, timezone: 'Africa/Tunis' },
  { id: 'algiers', title: 'Algiers', location: { latitude: 36.7538, longitude: 3.0588 }, timezone: 'Africa/Algiers' },
  { id: 'rabat', title: 'Rabat', location: { latitude: 34.0209, longitude: -6.8416 }, timezone: 'Africa/Casablanca' },
  { id: 'nouakchott', title: 'Nouakchott', location: { latitude: 18.0735, longitude: -15.9582 }, timezone: 'Africa/Nouakchott' },
  { id: 'dakar', title: 'Dakar', location: { latitude: 14.7167, longitude: -17.4677 }, timezone: 'Africa/Dakar' },
  { id: 'bamako', title: 'Bamako', location: { latitude: 12.6392, longitude: -8.0029 }, timezone: 'Africa/Bamako' },
  { id: 'niamey', title: 'Niamey', location: { latitude: 13.5137, longitude: 2.1098 }, timezone: 'Africa/Niamey' },
  { id: 'ndjamena', title: "N'Djamena", location: { latitude: 12.1348, longitude: 15.0557 }, timezone: 'Africa/Ndjamena' },
  { id: 'khartoum', title: 'Khartoum', location: { latitude: 15.5007, longitude: 32.5599 }, timezone: 'Africa/Khartoum' },
  { id: 'port-sudan', title: 'Port Sudan', location: { latitude: 19.6158, longitude: 37.2164 }, timezone: 'Africa/Khartoum' },
  { id: 'conakry', title: 'Conakry', location: { latitude: 9.6412, longitude: -13.5784 }, timezone: 'Africa/Conakry' },
  { id: 'banjul', title: 'Banjul', location: { latitude: 13.4549, longitude: -16.5790 }, timezone: 'Africa/Banjul' },
  { id: 'abuja', title: 'Abuja', location: { latitude: 9.0765, longitude: 7.3986 }, timezone: 'Africa/Lagos' },
  { id: 'yaounde', title: 'Yaoundé', location: { latitude: 3.8480, longitude: 11.5021 }, timezone: 'Africa/Douala' },
  { id: 'mogadishu', title: 'Mogadishu', location: { latitude: 2.0469, longitude: 45.3182 }, timezone: 'Africa/Mogadishu' },
  { id: 'djibouti', title: 'Djibouti', location: { latitude: 11.5890, longitude: 43.1450 }, timezone: 'Africa/Djibouti' },
  { id: 'moroni', title: 'Moroni', location: { latitude: -11.7022, longitude: 43.2551 }, timezone: 'Indian/Comoro' },
  { id: 'asmara', title: 'Asmara', location: { latitude: 15.3229, longitude: 38.9251 }, timezone: 'Africa/Asmara' },
  { id: 'dodoma', title: 'Dodoma', location: { latitude: -6.1629, longitude: 35.7516 }, timezone: 'Africa/Dar_es_Salaam' },
  { id: 'nairobi', title: 'Nairobi', location: { latitude: -1.2921, longitude: 36.8219 }, timezone: 'Africa/Nairobi' },
  { id: 'kampala', title: 'Kampala', location: { latitude: 0.3476, longitude: 32.5825 }, timezone: 'Africa/Kampala' },
  { id: 'islamabad', title: 'Islamabad', location: { latitude: 33.6844, longitude: 73.0479 }, timezone: 'Asia/Karachi' },
  { id: 'kabul', title: 'Kabul', location: { latitude: 34.5553, longitude: 69.2075 }, timezone: 'Asia/Kabul' },
  { id: 'male', title: 'Male', location: { latitude: 4.1755, longitude: 73.5093 }, timezone: 'Indian/Maldives' },
  { id: 'dhaka', title: 'Dhaka', location: { latitude: 23.8103, longitude: 90.4125 }, timezone: 'Asia/Dhaka' },
  { id: 'jakarta', title: 'Jakarta', location: { latitude: -6.2088, longitude: 106.8456 }, timezone: 'Asia/Jakarta' },
  { id: 'kuala-lumpur', title: 'Kuala Lumpur', location: { latitude: 3.1390, longitude: 101.6869 }, timezone: 'Asia/Kuala_Lumpur' },
  { id: 'astana', title: 'Astana', location: { latitude: 51.1605, longitude: 71.4704 }, timezone: 'Asia/Almaty' },
  { id: 'tashkent', title: 'Tashkent', location: { latitude: 41.2995, longitude: 69.2401 }, timezone: 'Asia/Tashkent' },
  { id: 'ashgabat', title: 'Ashgabat', location: { latitude: 37.9601, longitude: 58.3261 }, timezone: 'Asia/Ashgabat' },
  { id: 'bishkek', title: 'Bishkek', location: { latitude: 42.8746, longitude: 74.5698 }, timezone: 'Asia/Bishkek' },
  { id: 'dushanbe', title: 'Dushanbe', location: { latitude: 38.5598, longitude: 68.7738 }, timezone: 'Asia/Dushanbe' },
  { id: 'baku', title: 'Baku', location: { latitude: 40.4093, longitude: 49.8671 }, timezone: 'Asia/Baku' },
  { id: 'ankara', title: 'Ankara', location: { latitude: 39.9334, longitude: 32.8597 }, timezone: 'Europe/Istanbul' },
  { id: 'sarajevo', title: 'Sarajevo', location: { latitude: 43.8516, longitude: 18.3864 }, timezone: 'Europe/Sarajevo' },
  { id: 'tirana', title: 'Tirana', location: { latitude: 41.3275, longitude: 19.8187 }, timezone: 'Europe/Tirane' },
  { id: 'pristina', title: 'Pristina', location: { latitude: 42.6629, longitude: 21.1655 }, timezone: 'Europe/Belgrade' },
  { id: 'istanbul', title: 'Istanbul', location: { latitude: 41.0082, longitude: 28.9784 }, timezone: 'Europe/Istanbul' },
  { id: 'karachi', title: 'Karachi', location: { latitude: 24.8607, longitude: 67.0011 }, timezone: 'Asia/Karachi' },
  { id: 'lahore', title: 'Lahore', location: { latitude: 31.5204, longitude: 74.3587 }, timezone: 'Asia/Karachi' },
  { id: 'faisalabad', title: 'Faisalabad', location: { latitude: 31.4180, longitude: 73.0790 }, timezone: 'Asia/Karachi' },
  { id: 'mumbai', title: 'Mumbai', location: { latitude: 19.0760, longitude: 72.8777 }, timezone: 'Asia/Kolkata' },
  { id: 'delhi', title: 'Delhi', location: { latitude: 28.7041, longitude: 77.1025 }, timezone: 'Asia/Kolkata' },
  { id: 'hyderabad', title: 'Hyderabad', location: { latitude: 17.3850, longitude: 78.4867 }, timezone: 'Asia/Kolkata' },
  { id: 'bangalore', title: 'Bangalore', location: { latitude: 12.9716, longitude: 77.5946 }, timezone: 'Asia/Kolkata' },
  { id: 'kolkata', title: 'Kolkata', location: { latitude: 22.5726, longitude: 88.3639 }, timezone: 'Asia/Kolkata' },
  { id: 'ahmedabad', title: 'Ahmedabad', location: { latitude: 23.0225, longitude: 72.5714 }, timezone: 'Asia/Kolkata' },
  { id: 'chittagong', title: 'Chittagong', location: { latitude: 22.3569, longitude: 91.7832 }, timezone: 'Asia/Dhaka' },
  { id: 'surabaya', title: 'Surabaya', location: { latitude: -7.2575, longitude: 112.7521 }, timezone: 'Asia/Jakarta' },
  { id: 'bandung', title: 'Bandung', location: { latitude: -6.9175, longitude: 107.6191 }, timezone: 'Asia/Jakarta' },
  { id: 'medan', title: 'Medan', location: { latitude: 3.5952, longitude: 98.6722 }, timezone: 'Asia/Jakarta' },
  { id: 'jeddah', title: 'Jeddah', location: { latitude: 21.4858, longitude: 39.1925 }, timezone: 'Asia/Riyadh' },
  { id: 'mecca', title: 'Mecca', location: { latitude: 21.4225, longitude: 39.8262 }, timezone: 'Asia/Riyadh' },
  { id: 'medina', title: 'Medina', location: { latitude: 24.5247, longitude: 39.5692 }, timezone: 'Asia/Riyadh' },
  { id: 'dubai', title: 'Dubai', location: { latitude: 25.2048, longitude: 55.2708 }, timezone: 'Asia/Dubai' },
  { id: 'sharjah', title: 'Sharjah', location: { latitude: 25.3463, longitude: 55.4209 }, timezone: 'Asia/Dubai' },
  { id: 'alexandria', title: 'Alexandria', location: { latitude: 31.2001, longitude: 29.9187 }, timezone: 'Africa/Cairo' },
  { id: 'lagos', title: 'Lagos', location: { latitude: 6.5244, longitude: 3.3792 }, timezone: 'Africa/Lagos' },
  { id: 'kano', title: 'Kano', location: { latitude: 12.0022, longitude: 8.5919 }, timezone: 'Africa/Lagos' },
  { id: 'moscow', title: 'Moscow', location: { latitude: 55.7558, longitude: 37.6173 }, timezone: 'Europe/Moscow' },
  { id: 'saint-petersburg', title: 'Saint Petersburg', location: { latitude: 59.9343, longitude: 30.3351 }, timezone: 'Europe/Moscow' },
  { id: 'kazan', title: 'Kazan', location: { latitude: 55.8304, longitude: 49.0661 }, timezone: 'Europe/Moscow' },
  { id: 'ufa', title: 'Ufa', location: { latitude: 54.7388, longitude: 55.9721 }, timezone: 'Asia/Yekaterinburg' },
  { id: 'grozny', title: 'Grozny', location: { latitude: 43.3178, longitude: 45.6982 }, timezone: 'Europe/Moscow' },
  { id: 'makhachkala', title: 'Makhachkala', location: { latitude: 42.9849, longitude: 47.5047 }, timezone: 'Europe/Moscow' },
  { id: 'almaty', title: 'Almaty', location: { latitude: 43.2220, longitude: 76.8512 }, timezone: 'Asia/Almaty' },
  { id: 'urumqi', title: 'Ürümqi', location: { latitude: 43.8256, longitude: 87.6168 }, timezone: 'Asia/Urumqi' },
  { id: 'lanzhou', title: 'Lanzhou', location: { latitude: 36.0611, longitude: 103.8343 }, timezone: 'Asia/Shanghai' },
  { id: 'xian', title: "Xi'an", location: { latitude: 34.3416, longitude: 108.9398 }, timezone: 'Asia/Shanghai' },
  { id: 'singapore', title: 'Singapore', location: { latitude: 1.3521, longitude: 103.8198 }, timezone: 'Asia/Singapore' },
  { id: 'bangkok', title: 'Bangkok', location: { latitude: 13.7563, longitude: 100.5018 }, timezone: 'Asia/Bangkok' },
  { id: 'manila', title: 'Manila', location: { latitude: 14.5995, longitude: 120.9842 }, timezone: 'Asia/Manila' },
  { id: 'new-york', title: 'New York', location: { latitude: 40.7128, longitude: -74.0060 }, timezone: 'America/New_York' },
];

function getUtcOffset(timezone: string): number {
  try {
    const now = new Date();
    const formatter = new Intl.DateTimeFormat('en', { timeZone: timezone, timeZoneName: 'longOffset' });
    const parts = formatter.formatToParts(now);
    const tzPart = parts.find((p) => p.type === 'timeZoneName');
    if (!tzPart) return 0;
    const m = tzPart.value.match(/GMT([+-])(\d+)(?::(\d+))?/);
    if (!m) return 0;
    const sign = m[1] === '+' ? 1 : -1;
    const h = parseInt(m[2], 10);
    const min = m[3] ? parseInt(m[3], 10) : 0;
    return sign * (h + min / 60);
  } catch {
    return 0;
  }
}

const PRESETS_WITH_OFFSET: LocationPreset[] = RAW_PRESETS.map((p) => ({
  ...p,
  utcOffsetHours: getUtcOffset(p.timezone),
}));

/** Debug mode (localhost): curated city list only */
const DEBUG_RAW: Omit<LocationPreset, 'utcOffsetHours'>[] = [
  { id: 'mecca', title: 'Mecca', location: { latitude: 21.4225, longitude: 39.8262 }, timezone: 'Asia/Riyadh' },
  { id: 'istanbul', title: 'Istanbul', location: { latitude: 41.0082, longitude: 28.9784 }, timezone: 'Europe/Istanbul' },
  { id: 'kyiv', title: 'Kyiv', location: { latitude: 50.4501, longitude: 30.5234 }, timezone: 'Europe/Kyiv' },
  { id: 'jakarta', title: 'Jakarta', location: { latitude: -6.2088, longitude: 106.8456 }, timezone: 'Asia/Jakarta' },
  { id: 'cairo', title: 'Cairo', location: { latitude: 30.0444, longitude: 31.2357 }, timezone: 'Africa/Cairo' },
  { id: 'karachi', title: 'Karachi', location: { latitude: 24.8607, longitude: 67.0011 }, timezone: 'Asia/Karachi' },
  { id: 'dhaka', title: 'Dhaka', location: { latitude: 23.8103, longitude: 90.4125 }, timezone: 'Asia/Dhaka' },
  { id: 'tehran', title: 'Tehran', location: { latitude: 35.6892, longitude: 51.3890 }, timezone: 'Asia/Tehran' },
  { id: 'baghdad', title: 'Baghdad', location: { latitude: 33.3152, longitude: 44.3661 }, timezone: 'Asia/Baghdad' },
  { id: 'casablanca', title: 'Casablanca', location: { latitude: 33.5731, longitude: -7.5898 }, timezone: 'Africa/Casablanca' },
  { id: 'algiers', title: 'Algiers', location: { latitude: 36.7538, longitude: 3.0588 }, timezone: 'Africa/Algiers' },
  { id: 'khartoum', title: 'Khartoum', location: { latitude: 15.5007, longitude: 32.5599 }, timezone: 'Africa/Khartoum' },
  { id: 'kuala-lumpur', title: 'Kuala Lumpur', location: { latitude: 3.1390, longitude: 101.6869 }, timezone: 'Asia/Kuala_Lumpur' },
  { id: 'dubai', title: 'Dubai', location: { latitude: 25.2048, longitude: 55.2708 }, timezone: 'Asia/Dubai' },
  { id: 'kabul', title: 'Kabul', location: { latitude: 34.5553, longitude: 69.2075 }, timezone: 'Asia/Kabul' },
  { id: 'tashkent', title: 'Tashkent', location: { latitude: 41.2995, longitude: 69.2401 }, timezone: 'Asia/Tashkent' },
  { id: 'tunis', title: 'Tunis', location: { latitude: 36.8065, longitude: 10.1815 }, timezone: 'Africa/Tunis' },
  { id: 'dakar', title: 'Dakar', location: { latitude: 14.7167, longitude: -17.4677 }, timezone: 'Africa/Dakar' },
  { id: 'tokyo', title: 'Tokyo', location: { latitude: 35.6762, longitude: 139.6503 }, timezone: 'Asia/Tokyo' },
  { id: 'delhi', title: 'Delhi', location: { latitude: 28.7041, longitude: 77.1025 }, timezone: 'Asia/Kolkata' },
  { id: 'shanghai', title: 'Shanghai', location: { latitude: 31.2304, longitude: 121.4737 }, timezone: 'Asia/Shanghai' },
  { id: 'sao-paulo', title: 'São Paulo', location: { latitude: -23.5505, longitude: -46.6333 }, timezone: 'America/Sao_Paulo' },
  { id: 'mexico-city', title: 'Mexico City', location: { latitude: 19.4326, longitude: -99.1332 }, timezone: 'America/Mexico_City' },
  { id: 'mumbai', title: 'Mumbai', location: { latitude: 19.0760, longitude: 72.8777 }, timezone: 'Asia/Kolkata' },
  { id: 'beijing', title: 'Beijing', location: { latitude: 39.9042, longitude: 116.4074 }, timezone: 'Asia/Shanghai' },
  { id: 'lagos', title: 'Lagos', location: { latitude: 6.5244, longitude: 3.3792 }, timezone: 'Africa/Lagos' },
  { id: 'new-york', title: 'New York', location: { latitude: 40.7128, longitude: -74.0060 }, timezone: 'America/New_York' },
  { id: 'london', title: 'London', location: { latitude: 51.5074, longitude: -0.1278 }, timezone: 'Europe/London' },
  { id: 'paris', title: 'Paris', location: { latitude: 48.8566, longitude: 2.3522 }, timezone: 'Europe/Paris' },
  { id: 'moscow', title: 'Moscow', location: { latitude: 55.7558, longitude: 37.6173 }, timezone: 'Europe/Moscow' },
  { id: 'seoul', title: 'Seoul', location: { latitude: 37.5665, longitude: 126.978 }, timezone: 'Asia/Seoul' },
  { id: 'bangkok', title: 'Bangkok', location: { latitude: 13.7563, longitude: 100.5018 }, timezone: 'Asia/Bangkok' },
  { id: 'buenos-aires', title: 'Buenos Aires', location: { latitude: -34.6037, longitude: -58.3816 }, timezone: 'America/Argentina/Buenos_Aires' },
  { id: 'manila', title: 'Manila', location: { latitude: 14.5995, longitude: 120.9842 }, timezone: 'Asia/Manila' },
  { id: 'ho-chi-minh', title: 'Ho Chi Minh', location: { latitude: 10.8231, longitude: 106.6297 }, timezone: 'Asia/Ho_Chi_Minh' },
  { id: 'hong-kong', title: 'Hong Kong', location: { latitude: 22.3193, longitude: 114.1694 }, timezone: 'Asia/Hong_Kong' },
  { id: 'singapore', title: 'Singapore', location: { latitude: 1.3521, longitude: 103.8198 }, timezone: 'Asia/Singapore' },
  { id: 'sydney', title: 'Sydney', location: { latitude: -33.8688, longitude: 151.2093 }, timezone: 'Australia/Sydney' },
  { id: 'los-angeles', title: 'Los Angeles', location: { latitude: 34.0522, longitude: -118.2437 }, timezone: 'America/Los_Angeles' },
  { id: 'toronto', title: 'Toronto', location: { latitude: 43.6532, longitude: -79.3832 }, timezone: 'America/Toronto' },
  { id: 'berlin', title: 'Berlin', location: { latitude: 52.52, longitude: 13.405 }, timezone: 'Europe/Berlin' },
  { id: 'madrid', title: 'Madrid', location: { latitude: 40.4168, longitude: -3.7038 }, timezone: 'Europe/Madrid' },
  { id: 'rome', title: 'Rome', location: { latitude: 41.9028, longitude: 12.4964 }, timezone: 'Europe/Rome' },
  { id: 'johannesburg', title: 'Johannesburg', location: { latitude: -26.2041, longitude: 28.0473 }, timezone: 'Africa/Johannesburg' },
  { id: 'nairobi', title: 'Nairobi', location: { latitude: -1.2921, longitude: 36.8219 }, timezone: 'Africa/Nairobi' },
];

export const DEBUG_PRESETS: LocationPreset[] = DEBUG_RAW.map((p) => ({
  ...p,
  utcOffsetHours: getUtcOffset(p.timezone),
}));

// Production should use the same curated city list and ordering as localhost debug mode.
export const PRESETS_SORTED: LocationPreset[] = DEBUG_PRESETS;

export const PRESETS_BY_ID: Record<string, LocationPreset> = Object.fromEntries(PRESETS_SORTED.map((p) => [p.id, p]));

export const PRESETS_BY_TITLE: Record<string, LocationPreset> = Object.fromEntries(PRESETS_SORTED.map((p) => [p.title, p]));

export const MY_LOCATION_INSERT_INDEX = 0;

export const DEBUG_PRESETS_BY_TITLE: Record<string, LocationPreset> = Object.fromEntries(
  DEBUG_PRESETS.map((p) => [p.title, p]),
);
