# ============================================================
# Student & College Management System (SCMS)
# Fees & Financial Dues Module (Triggers Demonstration)
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from datetime import date
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, badge, format_currency

st.set_page_config(page_title="SCMS - Fees & Payments", page_icon="💳", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_fees"):
    logout()
render_project_info()

render_header("Fee Billing & Financial Settlements", "Tuition invoicing and transaction engine backed by integrity triggers", "💳")

st.info("""
💡 **DBMS Trigger Demonstrations — `trg_payment_before_insert` & `trg_payment_after_insert`**:
1. **Overpayment Prevention**: Rejects any payment exceeding the outstanding balance on the bill (`amount_paid > balance`).
2. **Automated Status Recalculation**: Immediately updates the fee bill's status to **Paid**, **Partially Paid**, or **Unpaid** based on total payment sum!
""")

tab_bills, tab_pay, tab_new_bill, tab_history, tab_test = st.tabs([
    "📋 Outstanding Fee Bills (SQL View)", 
    "💵 Record Fee Payment", 
    "🧾 Generate New Fee Bill", 
    "📜 Payment Transactions",
    "🧪 Test Payment Triggers"
])

# ------------------------------------------------------------
# TAB 1: VIEW FEE BILLS (VIEW: v_fee_dues)
# ------------------------------------------------------------
with tab_bills:
    st.subheader("University Fee Dues Registry (`v_fee_dues`)")
    try:
        dues = execute_query("SELECT * FROM v_fee_dues ORDER BY bill_id DESC")
        if dues:
            df_d = pd.DataFrame(dues)
            df_display = df_d[[
                "bill_number", "reg_number", "student_name", "semester_name", 
                "fee_type", "bill_amount", "paid_amount", "balance_due", "due_date", "status"
            ]].rename(columns={
                "bill_number": "Bill No",
                "reg_number": "Reg No",
                "student_name": "Student",
                "semester_name": "Semester",
                "fee_type": "Fee Type",
                "bill_amount": "Total Amount (₹)",
                "paid_amount": "Paid (₹)",
                "balance_due": "Balance Due (₹)",
                "due_date": "Due Date",
                "status": "Status"
            })
            st.dataframe(df_display, use_container_width=True, hide_index=True)
        else:
            st.info("No fee bills recorded.")
    except Exception as e:
        st.error(f"Failed to query v_fee_dues: {e}")

# ------------------------------------------------------------
# TAB 2: RECORD PAYMENT (Triggers 3 & 4)
# ------------------------------------------------------------
with tab_pay:
    st.subheader("Process Bill Payment")
    open_bills = execute_query("""
        SELECT 
            b.bill_id,
            b.bill_number,
            s.reg_number,
            CONCAT(s.first_name, ' ', s.last_name) AS student_name,
            b.amount,
            IFNULL((SELECT SUM(amount_paid) FROM payment WHERE bill_id = b.bill_id), 0.00) AS total_paid,
            (b.amount - IFNULL((SELECT SUM(amount_paid) FROM payment WHERE bill_id = b.bill_id), 0.00)) AS balance,
            b.status
        FROM fee_bill b
        JOIN student s ON b.student_id = s.student_id
        WHERE b.status <> 'Paid'
        ORDER BY b.bill_id DESC
    """)
    if open_bills:
        bill_map = {
            f"{b['bill_number']} | {b['reg_number']} - {b['student_name']} | Balance: ₹{float(b['balance']):,.2f} [{b['status']}]": b
            for b in open_bills
        }
        sel_bill_label = st.selectbox("Select Pending Fee Bill *", list(bill_map.keys()))
        target_bill = bill_map[sel_bill_label]
        cur_balance = float(target_bill["balance"])

        st.caption(f"Outstanding Balance on Bill: **₹{cur_balance:,.2f}**")

        with st.form("form_make_payment", clear_on_submit=True):
            col1, col2 = st.columns(2)
            with col1:
                receipt_no = st.text_input("Receipt Number *", value=f"REC-{date.today().strftime('%Y%m%d')}-{target_bill['bill_id']}")
                pay_amount = st.number_input("Payment Amount (₹) *", min_value=1.0, max_value=500000.0, value=min(cur_balance, 50000.0), step=500.0)
            with col2:
                pay_mode = st.selectbox("Payment Mode *", ["Online / UPI", "Net Banking", "Credit/Debit Card", "Demand Draft", "Cash"])
                tx_ref = st.text_input("Transaction / UTR Reference", placeholder="e.g. UPI/2026/993184")

            pay_date = st.date_input("Payment Date", value=date.today())

            if st.form_submit_button("💳 Confirm Payment", use_container_width=True):
                try:
                    execute_update("""
                        INSERT INTO payment (receipt_number, bill_id, amount_paid, payment_date, payment_mode, transaction_ref)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (receipt_no.strip(), target_bill["bill_id"], pay_amount, str(pay_date), pay_mode, tx_ref.strip() if tx_ref else None))
                    
                    # Fetch newly updated status from MySQL fee_bill
                    new_status = execute_query("SELECT status FROM fee_bill WHERE bill_id = %s", (target_bill["bill_id"],), fetch="one")["status"]
                    st.success(f"✅ Payment of ₹{pay_amount:,.2f} processed successfully!")
                    st.info(f"🔄 Database trigger updated Fee Bill Status to: **{new_status}**")
                    st.rerun()
                except ValueError as e:
                    st.error(f"🛑 {e}")
                except Exception as e:
                    st.error(f"🛑 Error: {e}")
    else:
        st.success("🎉 No outstanding bills pending payment.")

# ------------------------------------------------------------
# TAB 3: GENERATE NEW FEE BILL
# ------------------------------------------------------------
with tab_new_bill:
    st.subheader("Issue New Fee Bill")
    students = execute_query("SELECT student_id, reg_number, first_name, last_name FROM student ORDER BY reg_number")
    sems = execute_query("SELECT semester_id, semester_name, academic_year FROM semester ORDER BY start_date DESC")

    if students and sems:
        stu_map = {f"{s['reg_number']} - {s['first_name']} {s['last_name']}": s['student_id'] for s in students}
        sem_map = {f"{s['semester_name']} ({s['academic_year']})": s['semester_id'] for s in sems}

        with st.form("form_create_bill", clear_on_submit=True):
            col1, col2 = st.columns(2)
            with col1:
                sel_stu = st.selectbox("Student *", list(stu_map.keys()))
                sel_sem = st.selectbox("Semester *", list(sem_map.keys()))
                bill_num = st.text_input("Bill Number *", placeholder="e.g. BILL-2026-008")
            with col2:
                fee_type = st.selectbox("Fee Type *", ["Tuition Fee", "Hostel Fee", "Examination Fee", "Library Fee", "Composite Fee"])
                bill_amt = st.number_input("Amount (₹) *", min_value=100.0, max_value=1000000.0, value=150000.0, step=1000.0)
                due_date = st.date_input("Due Date *", value=date.today())

            if st.form_submit_button("🧾 Issue Fee Bill", use_container_width=True):
                if not bill_num.strip():
                    st.error("Bill Number is required.")
                else:
                    try:
                        execute_update("""
                            INSERT INTO fee_bill (bill_number, student_id, semester_id, fee_type, amount, due_date, issue_date, status)
                            VALUES (%s, %s, %s, %s, %s, %s, CURDATE(), 'Unpaid')
                        """, (bill_num.strip(), stu_map[sel_stu], sem_map[sel_sem], fee_type, bill_amt, str(due_date)))
                        st.success(f"✅ Fee Bill '{bill_num}' issued successfully.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Failed to issue bill: {e}")

# ------------------------------------------------------------
# TAB 4: PAYMENT TRANSACTIONS HISTORY
# ------------------------------------------------------------
with tab_history:
    st.subheader("Historical Payments Audit")
    payments = execute_query("""
        SELECT 
            p.payment_id,
            p.receipt_number,
            b.bill_number,
            s.reg_number,
            CONCAT(s.first_name, ' ', s.last_name) AS student_name,
            p.amount_paid,
            p.payment_date,
            p.payment_mode,
            p.transaction_ref
        FROM payment p
        JOIN fee_bill b ON p.bill_id = b.bill_id
        JOIN student s ON b.student_id = s.student_id
        ORDER BY p.payment_id DESC
    """)
    if payments:
        df_p = pd.DataFrame(payments).rename(columns={
            "receipt_number": "Receipt No",
            "bill_number": "Bill No",
            "reg_number": "Reg No",
            "student_name": "Student",
            "amount_paid": "Amount Paid (₹)",
            "payment_date": "Payment Date",
            "payment_mode": "Mode",
            "transaction_ref": "Reference"
        })
        st.dataframe(df_p.drop(columns=["payment_id"]), use_container_width=True, hide_index=True)
    else:
        st.info("No payment records recorded.")

# ------------------------------------------------------------
# TAB 5: TRIGGER TEST LAB
# ------------------------------------------------------------
with tab_test:
    st.subheader("🧪 Live Trigger Validation Lab (PBL Viva Demo)")
    st.markdown("### Test: Overpayment Beyond Outstanding Balance")
    st.markdown("""
    Attempts to submit a payment exceeding the outstanding balance on a bill.
    - E.g. If balance is ₹5,000, attempting to pay ₹100,000 will be caught by `trg_payment_before_insert`.
    """)
    if st.button("Run Overpayment Test", key="test_overpay_btn"):
        try:
            # Query an unpaid bill
            unpaid_bill = execute_query("""
                SELECT b.bill_id, b.bill_number, b.amount,
                       IFNULL((SELECT SUM(amount_paid) FROM payment WHERE bill_id = b.bill_id), 0.00) AS paid
                FROM fee_bill b
                WHERE b.status <> 'Paid'
                LIMIT 1
            """, fetch="one")

            if unpaid_bill:
                b_id = unpaid_bill["bill_id"]
                bal = float(unpaid_bill["amount"]) - float(unpaid_bill["paid"])
                attempt_amount = bal + 50000.0  # Intentional overpayment
                execute_update("""
                    INSERT INTO payment (receipt_number, bill_id, amount_paid, payment_date, payment_mode)
                    VALUES ('TEST-OVERPAY-DEMO', %s, %s, CURDATE(), 'Cash')
                """, (b_id, attempt_amount))
                st.error("Unexpected: Overpayment allowed!")
            else:
                st.info("No open bill available to test.")
        except ValueError as e:
            st.success(f"✅ Trigger fired as expected:\n\n**{e}**")
