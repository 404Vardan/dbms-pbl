const API_BASE = '/api';

export async function apiRequest(endpoint, options = {}) {
  const token = localStorage.getItem('scms_token');
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers || {})
  };

  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const errorMsg = data.error || data.message || `Request failed with status ${response.status}`;
    throw new Error(errorMsg);
  }

  return data;
}

export const api = {
  // Auth
  login: (email, password) => apiRequest('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),

  // Dashboard
  getDashboardStats: () => apiRequest('/dashboard/stats'),

  // Students
  getStudents: () => apiRequest('/students'),
  getStudentDetails: (id) => apiRequest(`/students/${id}`),
  admitStudent: (payload) => apiRequest('/students/admit', { method: 'POST', body: JSON.stringify(payload) }),

  // Registration
  getRegistrationOptions: () => apiRequest('/registration/options'),
  registerCourse: (student_id, section_id) => apiRequest('/registration', { method: 'POST', body: JSON.stringify({ student_id, section_id }) }),

  // Attendance
  getAttendanceSections: () => apiRequest('/attendance/sections'),
  getAttendanceRoster: (section_id, date) => apiRequest(`/attendance/roster?section_id=${section_id}&date=${date}`),
  saveAttendance: (payload) => apiRequest('/attendance/save', { method: 'POST', body: JSON.stringify(payload) }),

  // Examinations
  getExamData: (section_id, exam_type) => apiRequest(`/examinations/data?section_id=${section_id}&exam_type=${exam_type}`),
  recordExamMarks: (payload) => apiRequest('/examinations/record', { method: 'POST', body: JSON.stringify(payload) }),

  // Fees
  getFeesData: () => apiRequest('/fees/data'),
  createBill: (payload) => apiRequest('/fees/bill', { method: 'POST', body: JSON.stringify(payload) }),
  recordPayment: (payload) => apiRequest('/fees/payment', { method: 'POST', body: JSON.stringify(payload) }),

  // Reports
  getReport: (tab) => apiRequest(`/reports/${tab}`),

  // Academic Structure
  getDepartments: () => apiRequest('/departments'),
  getCourses: () => apiRequest('/courses'),
  createCourse: (payload) => apiRequest('/courses', { method: 'POST', body: JSON.stringify(payload) }),
  getFaculty: () => apiRequest('/faculty'),
  getSemesters: () => apiRequest('/semesters'),
  getSections: () => apiRequest('/sections'),
  createSection: (payload) => apiRequest('/sections', { method: 'POST', body: JSON.stringify(payload) })
};
