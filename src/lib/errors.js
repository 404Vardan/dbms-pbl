/**
 * Maps database errors and constraints to clear human-readable messages.
 */
export function formatDbError(err) {
  if (!err) return 'An unexpected error occurred.';
  
  const message = err.message || err.details || String(err);

  // Custom hint codes and messages from triggers.sql
  if (message.includes('DUPLICATE_REGISTRATION') || message.includes('already registered in')) {
    return 'Registration Failed: Student is already registered in this course/section.';
  }
  if (message.includes('DUPLICATE_COURSE') || message.includes('another section of this course')) {
    return 'Registration Failed: Student is already registered in another section for this course in the same semester.';
  }
  if (message.includes('SECTION_FULL') || message.includes('seats are taken')) {
    return 'Registration Blocked: This section has reached maximum student capacity.';
  }
  if (message.includes('STUDENT_NOT_ACTIVE') || message.includes('Only Active students')) {
    return 'Registration Blocked: Only active students can be enrolled in sections.';
  }
  if (message.includes('OVERPAYMENT') || message.includes('Overpayment rejected')) {
    return 'Payment Rejected: Total payment cannot exceed the remaining balance due.';
  }
  if (message.includes('FUTURE_DATE') || message.includes('future date')) {
    return 'Invalid Date: Attendance cannot be recorded for a future date.';
  }
  if (message.includes('OUTSIDE_SEMESTER') || message.includes('outside the semester')) {
    return 'Invalid Date: Date falls outside the scheduled semester period.';
  }
  if (message.includes('REGISTRATION_DROPPED')) {
    return 'Operation Not Allowed: The student registration has been dropped.';
  }

  // Constraint name checks from schema.sql
  if (message.includes('uq_registration_student_section')) {
    return 'Registration Failed: Duplicate registration for this section.';
  }
  if (message.includes('ck_examination_marks')) {
    return 'Invalid Marks: Examination marks must be between 0 and 100, and cannot exceed max marks.';
  }
  if (message.includes('ck_examination_marks_max')) {
    return 'Invalid Marks: Marks cannot exceed the specified maximum marks.';
  }
  if (message.includes('ck_attendance_status')) {
    return 'Invalid Status: Attendance status must be Present, Absent, or Late.';
  }
  if (message.includes('uq_attendance_registration_date')) {
    return 'Duplicate Attendance: Attendance for this student on this date is already recorded.';
  }
  if (message.includes('uq_fee_bill_student_semester')) {
    return 'Duplicate Bill: A fee bill for this student and semester already exists.';
  }
  if (message.includes('uq_payment_reference')) {
    return 'Duplicate Reference: This transaction/reference number has already been used.';
  }
  if (message.includes('ck_payment_amount')) {
    return 'Invalid Amount: Payment amount must be greater than zero.';
  }
  if (message.includes('ck_section_capacity')) {
    return 'Invalid Capacity: Section capacity must be at least 1.';
  }
  if (message.includes('uq_student_reg_no')) {
    return 'Duplicate Reg No: A student with this registration number already exists.';
  }
  if (message.includes('uq_student_email')) {
    return 'Duplicate Email: A student with this email address already exists.';
  }
  if (message.includes('fk_')) {
    return 'Integrity Constraint: Referenced record does not exist or cannot be modified.';
  }

  return message;
}
