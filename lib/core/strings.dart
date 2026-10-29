/// Centralized user-visible strings for localization and consistency.
/// Primary language: Thai, fallback: English (Assumption A2 in AGENTS.md).
class AppStrings {
  // App Title
  static const String appTitle = 'Chess App';

  // Game Status
  static const String whiteTurn = 'ตาหมากขาวเดิน';
  static const String blackTurn = 'ตาหมากดำเดิน';
  static const String check = 'รุก!';
  static const String checkmate = 'รุกฆาต!';
  static const String stalemate = 'เสมอ (อับจน / Stalemate)';
  static const String drawThreefold = 'เสมอ (ตำแหน่งเดิมซ้ำ 3 ครั้ง)';
  static const String drawFiftyMove = 'เสมอ (กฎ 50 ตาเดิน)';
  static const String drawInsufficient = 'เสมอ (แต้มหมากไม่พอเอาชนะ)';
  static const String drawAgreed = 'เสมอโดยตกลงกัน';
  static const String whiteWon = 'หมากขาวชนะ (1-0)';
  static const String blackWon = 'หมากดำชนะ (0-1)';
  static const String drawResult = 'เสมอ (1/2-1/2)';

  // Actions
  static const String newGame = 'เริ่มเกมใหม่';
  static const String undo = 'ย้อนตาเดิน';
  static const String resign = 'ยอมแพ้';
  static const String restart = 'เล่นใหม่';
  static const String confirmResign = 'คุณแน่ใจหรือไม่ว่าต้องการยอมแพ้?';
  static const String cancel = 'ยกเลิก';
  static const String confirm = 'ยืนยัน';

  // Promotion Dialog
  static const String choosePromotion = 'เลือกหมากที่จะเลื่อนขั้น (Promotion)';
  static const String queen = 'ควีน (Queen)';
  static const String rook = 'เรือ (Rook)';
  static const String bishop = 'บิชอป (Bishop)';
  static const String knight = 'ม้า (Knight)';

  // Players & Modes
  static const String white = 'หมากขาว';
  static const String black = 'หมากดำ';
  static const String humanVsHuman = 'เล่น 2 คน (Pass & Play)';
  static const String playVsBot = 'เล่นกับบอท (Play vs Bot)';
  static const String gameMode = 'โหมดการเล่น';
  static const String botLevel = 'ระดับความยากบอท';
  static const String easyLevel = 'ง่าย (Easy)';
  static const String mediumLevel = 'ปานกลาง (Medium)';
  static const String hardLevel = 'ยาก (Hard)';
  static const String playAsWhite = 'เล่นเป็นหมากขาว';
  static const String playAsBlack = 'เล่นเป็นหมากดำ';
  static const String botThinking = 'บอทกำลังคิด...';
  static const String playerWon = 'คุณชนะ!';
  static const String botWon = 'บอทชนะ!';

  // Clock & Time Control
  static const String timeControl = 'การตั้งเวลา';
  static const String unlimited = 'ไม่จำกัดเวลา (Unlimited)';
  static const String blitz3p2 = '3 นาที + 2 วิ (Blitz)';
  static const String blitz5p0 = '5 นาที (Blitz)';
  static const String rapid10p0 = '10 นาที (Rapid)';
  static const String rapid15p10 = '15 นาที + 10 วิ (Rapid)';
  static const String whiteTimedOut = 'หมากขาวหมดเวลา - หมากดำชนะ (0-1)';
  static const String blackTimedOut = 'หมากดำหมดเวลา - หมากขาวชนะ (1-0)';
}
