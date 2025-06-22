// ---- functions/index.js (ฉบับสมบูรณ์ Final) ----
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

admin.initializeApp();
const db = admin.firestore();


// --- Function สำหรับคำนวณช่องจอดว่าง ---
exports.getAvailableSpots = functions
  .region("asia-southeast1")
  .https.onCall(async (data, context) => {
    if (!data.checkIn || !data.checkOut) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "กรุณาระบุวันที่เข้าและออก"
      );
    }

    const checkIn = new Date(data.checkIn);
    const checkOut = new Date(data.checkOut);

    try {
      const configRef = db.collection("config").doc("Nez0wZtFS8JgS9iWorp5");
      const configDoc = await configRef.get();
      if (!configDoc.exists) {
        throw new functions.https.HttpsError("not-found", "ไม่พบข้อมูลการตั้งค่า");
      }
      const totalCapacity = configDoc.data().totalCapacity ?? 100;

      const bookingsRef = db.collection("bookings");
      const overlappingBookingsSnapshot = await bookingsRef
        .where("bookingStatus", "in", ["CONFIRMED", "COMPLETED"])
        .where("checkOutDateTime", ">", admin.firestore.Timestamp.fromDate(checkIn))
        .get();

      let overlappingCount = 0;
      overlappingBookingsSnapshot.forEach(doc => {
        const booking = doc.data();
        const bookingCheckIn = booking.checkInDateTime.toDate();
        if (bookingCheckIn < checkOut) {
          overlappingCount++;
        }
      });

      const availableSpots = totalCapacity - overlappingCount;
      return { availableSpots: availableSpots >= 0 ? availableSpots : 0 };

    } catch (error) {
      console.error("Error in getAvailableSpots:", error);
      throw new functions.https.HttpsError("internal", "ไม่สามารถคำนวณช่องจอดได้");
    }
  });

// --- Function สำหรับตรวจสอบโปรโมชั่นโค้ด ---
exports.validatePromoCode = functions
  .region("asia-southeast1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "...");
    }
    if (!data.code) {
      throw new functions.https.HttpsError("invalid-argument", "...");
    }

    const code = data.code.toUpperCase();
    const promoCodeRef = db.collection("promo_codes").doc(code);

    try {
      const doc = await promoCodeRef.get();
      if (!doc.exists) {
        throw new functions.https.HttpsError("not-found", "ไม่พบโปรโมชั่นโค้ดนี้");
      }

      const promoData = doc.data();

      if (!promoData.isActive) {
        throw new functions.https.HttpsError("failed-precondition", "โค้ดนี้ไม่สามารถใช้งานได้ในขณะนี้");
      }

      // --- 1. ตรวจสอบวันหมดอายุ ---
      if (promoData.expiresAt && promoData.expiresAt.toDate() < new Date()) {
         throw new functions.https.HttpsError("failed-precondition", "โค้ดนี้หมดอายุแล้ว");
      }

      // --- 2. ตรวจสอบจำนวนการใช้งาน ---
      if (promoData.usageLimit != null && promoData.timesUsed >= promoData.usageLimit) {
        throw new functions.https.HttpsError("failed-precondition", "โค้ดนี้ถูกใช้ครบจำนวนสิทธิ์แล้ว");
      }
      
      // ถ้าทุกอย่างถูกต้อง ส่งข้อมูลส่วนลดกลับไป
      return {
        code: doc.id,
        discountType: promoData.discountType,
        discountValue: promoData.discountValue,
      };
    } catch (error) {
      console.error("Error in validatePromoCode:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "เกิดข้อผิดพลาดในการตรวจสอบโค้ด");
    }
  });

// --- Function สำหรับอัปโหลดสลิป ---
exports.uploadSlip = functions
  .region("asia-southeast1")
  .runWith({ memory: "512MB", timeoutSeconds: 120 })
  .https.onCall(async (data, context) => {
    if (!context.auth) { throw new functions.https.HttpsError("unauthenticated", "Function must be called while authenticated."); }
    if (!data.fileBase64 || !data.fileName || !data.contentType) { throw new functions.https.HttpsError("invalid-argument", "Missing required data for file upload."); }

    const R2_ACCOUNT_ID = "d24e0130e15df92c2329edcab46fa8cd";
    const R2_ACCESS_KEY_ID = "e1596c1189116172b861596185508e38"; // ใช้ Key ล่าสุดที่คุณยืนยัน
    const R2_SECRET_ACCESS_KEY = "78d99058b813dba669d469f5b1b30d816952e0870e359e6d8e4db8767af34c94"; // ใช้ Key ล่าสุดที่คุณยืนยัน

    const R2_BUCKET_NAME = "upark-slips-sakarin123";
    const PUBLIC_R2_URL = "https://pub-7c2799ad567b4cb29a25db3b06802777.r2.dev";

    const s3 = new S3Client({
      region: "auto",
      endpoint: `https://` + R2_ACCOUNT_ID + `.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID,
        secretAccessKey: R2_SECRET_ACCESS_KEY,
      },
      signatureVersion: 'v4', // เพิ่มการบังคับใช้ signature v4
    });

    try {
      const buffer = Buffer.from(data.fileBase64, "base64");
      const putCommand = new PutObjectCommand({
        Bucket: R2_BUCKET_NAME,
        Key: data.fileName,
        Body: buffer,
        ContentType: data.contentType,
        ACL: 'public-read',
      });
      await s3.send(putCommand);
      const publicUrl = `${PUBLIC_R2_URL}/${data.fileName}`;
      return { success: true, publicUrl: publicUrl };
    } catch (error) {
      console.error("R2 Upload Error:", error);
      throw new functions.https.HttpsError("internal", "Failed to upload slip to storage.", error);
    }
  });

  // ---- เพิ่มฟังก์ชัน addAdminRole ----

// ---- วางทับ exports.addAdminRole เดิม ----

exports.addAdminRole = functions
  .region("asia-southeast1")
  .https.onCall(async (data, context) => {
    // --- เพิ่มการตรวจสอบข้อมูลที่ส่งเข้ามา ---
    if (!data.email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Please provide an 'email' in the data payload."
      );
    }
    // ------------------------------------

    const email = data.email;
    try {
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().setCustomUserClaims(user.uid, { admin: true });
      return { message: `Success! ${email} is now an admin.` };
    } catch (error) {
      console.error("Error adding admin role:", error);
      // ส่ง Error ที่มีความหมายมากขึ้นกลับไป
      throw new functions.https.HttpsError("internal", error.message, error);
    }
  });
  // ---- เพิ่ม 2 ฟังก์ชันนี้ใน functions/index.js ----

// ฟังก์ชันสำหรับ "เพิกถอน" สิทธิ์ Admin
exports.removeAdminRole = functions
  .region("asia-southeast1")
  .https.onCall(async (data, context) => {
    // TODO: เพิ่มการตรวจสอบว่าเป็น Super Admin หรือไม่
    if (!data.email) { throw new functions.https.HttpsError("invalid-argument", "Please provide an 'email'."); }

    try {
      const user = await admin.auth().getUserByEmail(data.email);
      // ตั้งค่า Custom Claim กลับไปเป็น object ว่างๆ หรือลบ admin: true ออก
      await admin.auth().setCustomUserClaims(user.uid, { admin: false });
      return { message: `Success! ${data.email} is no longer an admin.` };
    } catch (error) {
      console.error("Error removing admin role:", error);
      throw new functions.https.HttpsError("internal", error.message, error);
    }
  });

// ฟังก์ชันสำหรับ "ดึงรายชื่อผู้ใช้ทั้งหมด"
exports.listAllUsers = functions
  .region("asia-southeast1")
  .https.onCall(async (data, context) => {
    // ตรวจสอบว่าเป็น Admin หรือไม่ก่อนเรียกใช้
    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError("permission-denied", "Only admins can list users.");
    }

    try {
      const listUsersResult = await admin.auth().listUsers(1000); // ดึงได้สูงสุด 1000 คนต่อครั้ง
      const users = listUsersResult.users.map((userRecord) => {
        return {
          uid: userRecord.uid,
          email: userRecord.email,
          displayName: userRecord.displayName,
          isAdmin: !!userRecord.customClaims?.admin, // เช็คว่ามี claim admin หรือไม่
        };
      });
      return { users: users };
    } catch (error) {
      console.error("Error listing users:", error);
      throw new functions.https.HttpsError("internal", "Failed to list users.", error);
    }
  });