import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import numpy as np

# 1. Page Configuration
st.set_page_config(
    page_title="Candidate Intelligence Hub", 
    layout="wide", 
    initial_sidebar_state="collapsed"
)

# 2. Data Loading & Cleaning Engine
@st.cache_data
def process_timesheet_data():
    df = pd.read_excel("/Users/A30061/Downloads/Timesheet Report.xlsx")
    df = df.dropna(subset=['Month Year'])
    
    df['Start Date'] = pd.to_datetime(df['Start Date'], errors='coerce')
    df['End Date'] = pd.to_datetime(df['End Date'], errors='coerce')
    df['Submitted On'] = pd.to_datetime(df['Submitted On'], errors='coerce')
    
    for col in ['Total Days', 'Total Hours', 'Present', 'Absent']:
        df[col] = pd.to_numeric(df[col], errors='coerce')
        
    df['Attendance_Rate'] = (df['Present'] / df['Total Days']) * 100
    df['Attendance_Rate'] = df['Attendance_Rate'].fillna(0)
    
    # Weekly Submission Policy Logic
    days_to_monday = 7 - df['End Date'].dt.weekday
    df['Submission_Deadline'] = df['End Date'] + pd.to_timedelta(days_to_monday, unit='D')
    df['Submission_Lag_Days'] = (df['Submitted On'] - df['End Date']).dt.days
    
    df['Rule_Status'] = np.where(
        df['Submitted On'].isna(), 'Missing Submission',
        np.where(df['Submitted On'] > df['Submission_Deadline'], 'Late Submission', 'On-Time')
    )
    
    return df

df = process_timesheet_data()

# ------------------------------------------------------------------
# 3. ADVANCED CANDIDATE BEHAVIORAL ANALYTICS
# ------------------------------------------------------------------
total_hours_sum = df['Total Hours'].sum()
avg_attendance_pct = df['Attendance_Rate'].mean()
total_absent_days = df['Absent'].sum()

# Work Intensity: Average hours worked per active "Present" day
df['Hours_Per_Present_Day'] = df['Total Hours'] / df['Present']
avg_daily_intensity = df['Hours_Per_Present_Day'].mean()

# Burnout Risk Check: Find weeks where daily intensity exceeds 9 hours/day
high_intensity_weeks = len(df[df['Hours_Per_Present_Day'] > 9])

# Administrative Reliability (On-time rate)
on_time_count = len(df[df['Rule_Status'] == 'On-Time'])
compliance_rate = (on_time_count / len(df)) * 100 if len(df) > 0 else 0
avg_submission_lag = df['Submission_Lag_Days'].mean()

# Approval Friction Profile
total_rejected = len(df[df['Approval Status'].str.lower().str.contains('rejected', na=False)])

# ------------------------------------------------------------------
# 4. USER INTERFACE LAYOUT
# ------------------------------------------------------------------
st.title("📊 Candidate Behavioral Profile & Timesheet Analytics")
st.subheader(f"Data-Driven Performance & Habits Story Study")
st.markdown("---")

# ROW 1: Core Summary Statistics
kpi1, kpi2, kpi3, kpi4 = st.columns(4)
kpi1.metric("Total Hours Contributed", f"{total_hours_sum:,.1f} Hrs")
kpi2.metric("Punctuality Rate (Admin)", f"{compliance_rate:.1f}%")
kpi3.metric("Avg Daily Work Intensity", f"{avg_daily_intensity:.1f} Hrs/Day")
kpi4.metric("Total Absenteeism", f"{int(total_absent_days)} Days")

st.markdown("---")

# ROW 2: Layout Grid (Charts Left, Candidate Evaluation Right)
left_layout_col, right_layout_col = st.columns([2, 1])

with left_layout_col:
    st.subheader("📈 Interactive Charts")
    plot_col1, plot_col2 = st.columns(2)
    
    with plot_col1:
        # Chart A: Volumetric Work Capacity
        trend_data = df.groupby('Month Year')['Total Hours'].sum().reset_index()
        fig_trend = px.bar(trend_data, x='Month Year', y='Total Hours', title="Monthly Volumetric Work Capacity", color_discrete_sequence=['#2B5B84'])
        st.plotly_chart(fig_trend, use_container_width=True)
        
        # Chart C: Attendance Matrix
        attendance_data = df.groupby('Month Year')[['Present', 'Absent']].sum().reset_index()
        fig_attendance = go.Figure(data=[
            go.Bar(name='Present Days', x=attendance_data['Month Year'], y=attendance_data['Present'], marker_color='#2ecc71'),
            go.Bar(name='Absent Days', x=attendance_data['Month Year'], y=attendance_data['Absent'], marker_color='#e74c3c')
        ])
        fig_attendance.update_layout(barmode='stack', title="Presence vs Absenteeism Ratios", hovermode="x unified")
        st.plotly_chart(fig_attendance, use_container_width=True)

    with plot_col2:
        # Chart B: Compliance Split
        rule_data = df['Rule_Status'].value_counts().reset_index()
        fig_rule = px.pie(rule_data, names='Rule_Status', values='count', hole=0.4, title="Weekly Submission Compliance",
                          color='Rule_Status', color_discrete_map={'On-Time': '#2ecc71', 'Late Submission': '#e67e22', 'Missing Submission': '#e74c3c'})
        st.plotly_chart(fig_rule, use_container_width=True)
        
        # Chart D: Work Intensity Progression
        fig_intensity = px.line(df.sort_values(by='Start Date'), x='Start Date', y='Hours_Per_Present_Day', markers=True,
                                title="Work Intensity (Hours Clocked per Present Day)", color_discrete_sequence=['#9b59b6'])
        st.plotly_chart(fig_intensity, use_container_width=True)

# ROW 2 - RIGHT SIDE: Candidate Insights & Behavioral Persona
with right_layout_col:
    st.subheader("👤 Candidate Behavioral Persona")
    
    with st.container(border=True):
        st.markdown("### 🛠️ Work Delivery & Output Pace")
        st.write(f"This candidate sustains a solid baseline output, accumulating **{total_hours_sum:,.1f} hours** across the observed scope.")
        st.write(f"The candidate's core daily intensity sits at **{avg_daily_intensity:.1f} hours per day** worked. ")
        if high_intensity_weeks > 0:
            st.write(f"⚠️ **Burnout/Overtime Risk:** There are **{high_intensity_weeks} reporting periods** where the candidate pushed beyond a 9-hour daily average. This suggests heavy task sprint behaviors or poor project scope control.")
            
    with st.container(border=True):
        st.markdown("### 🗂️ Administrative Reliability & Compliance")
        st.write(f"The candidate logs an administrative deadline adherence rate of **{compliance_rate:.1f}%**.")
        if compliance_rate < 70:
            st.write(f"❌ **Low Operational Discipline:** With an average lag of **{avg_submission_lag:.1f} days**, this candidate routinely treats timesheet deadlines as optional. They require active management follow-up to remain aligned with operational workflows.")
        elif compliance_rate < 90:
            st.write(f"⚠️ **Inconsistent Punctuality:** The candidate generally respects payroll deadlines but is prone to sliding behind during high-intensity operational shifts.")
        else:
            st.write(f"✅ **Exceptional Administrative Discipline:** The candidate handles corporate timelines reliably, indicating highly independent operational habits.")

    with st.container(border=True):
        st.markdown("### 🩺 Reliability & Friction Risk")
        st.write(f"**Attendance Integrity:** The candidate maintains a **{avg_attendance_pct:.1f}%** baseline attendance score, having missed **{int(total_absent_days)} scheduled working days** over this period.")
        if total_rejected > 0:
            st.write(f"🚨 **Accuracy Issues:** Management rejected **{total_rejected} timesheet records**. This points to formatting mismatch disputes, clock-in errors, or misallocated hours requiring manual intervention.")
        else:
            st.write("✅ **High Reporting Integrity:** Zero timesheets were rejected by managers, showing that hours are reported accurately and transparently without booking errors.")

st.markdown("---")
# ROW 3: Styled Audit Table
st.subheader("🔍 Data Audit Trail")
st.dataframe(df.sort_values(by='Start Date', ascending=False), use_container_width=True)