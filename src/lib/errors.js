/**
 * Maps database errors and MySQL constraints to friendly messages
 */
export function formatDbError(err) {
  if (!err) return 'An unexpected error occurred.';
  const message = err.message || err.details || String(err);

  if (message.includes('maximum student capacity')) {
    return 'Registration Blocked: This section has reached maximum student capacity.';
  }
  if (message.includes('another section for this course')) {
    return 'Registration Failed: Student is already registered in another section for this course in the same semester.';
  }
  if (message.includes('Only Active students')) {
    return 'Registration Blocked: Only active students can be enrolled in sections.';
  }
  if (message.includes('Total payment cannot exceed')) {
    return 'Payment Rejected: Total payment cannot exceed the remaining balance due.';
  }
  if (message.includes('Duplicate entry')) {
    if (message.includes('uq_registration_student_section')) {
      return 'Registration Failed: Student is already enrolled in this section.';
    }
    if (message.includes('uq_student_reg_no')) {
      return 'Duplicate Record: A student with this registration number already exists.';
    }
    if (message.includes('uq_student_email')) {
      return 'Duplicate Record: A student with this email address already exists.';
    }
    if (message.includes('uq_payment_reference')) {
      return 'Duplicate Reference: This transaction/reference number has already been recorded.';
    }
    return 'Duplicate entry violation detected in database.';
  }
  if (message.includes('Check constraint') || message.includes('CONSTRAINT `ck_')) {
    return 'Integrity Check Failed: Entered values violate column CHECK constraints.';
  }
  return message;
}
