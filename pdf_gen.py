"""
Digital Route Card System — PDF Generation
Generates a traveler PDF document for a route card.
"""

import io
from datetime import datetime


def generate_traveler_pdf(card: dict) -> bytes:
    """Generate a PDF traveler document for the given route card.

    Uses reportlab if available, otherwise falls back to a simple
    text-based PDF.
    """
    try:
        return _generate_with_reportlab(card)
    except ImportError:
        return _generate_simple_pdf(card)
def _generate_with_reportlab(card: dict) -> bytes:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import mm
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
    import qrcode

    buf = io.BytesIO()
    # Excel template is usually wide, let's use landscape for more columns
    doc = SimpleDocTemplate(buf, pagesize=landscape(A4), topMargin=15*mm, bottomMargin=15*mm,
                            leftMargin=10*mm, rightMargin=10*mm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("TravelerTitle", parent=styles["Title"],
                                  fontSize=16, textColor=colors.HexColor("#082b63"))

    elements = []

    title_paragraphs = [
        Paragraph("ROUTE CARD", title_style),
    ]

    # Generate QR Code for Work Order
    qr_img = None
    wo_num = card.get("workOrderNumber", "")
    card_id = card.get("id", "")
    if card_id:
        qr_url = f"http://localhost:40536/#/card-detail?id={card_id}"
        qr = qrcode.QRCode(version=1, box_size=10, border=0)
        qr.add_data(qr_url)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        qr_buf = io.BytesIO()
        img.save(qr_buf, format="PNG")
        qr_buf.seek(0)
        qr_img = Image(qr_buf, width=25*mm, height=25*mm)

    if qr_img:
        header_table = Table([[title_paragraphs, qr_img]], colWidths=[200*mm, 30*mm])
        header_table.setStyle(TableStyle([
            ('ALIGN', (1, 0), (1, 0), 'RIGHT'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ]))
        elements.append(header_table)
    else:
        elements.extend(title_paragraphs)

    elements.append(Spacer(1, 5*mm))

    # Header Data Mapping matching Excel
    info_data = [
        ["", "", "", "WO No:", card.get("workOrderNumber", "")],
        ["Station / Job Name:", card.get("jobName", ""), "", "Mfg Qty:", f"{card.get('batchQuantity', '')} NOS"],
        ["Build / Rev:", card.get("partRevision", "A"), "", "Released Date:", card.get("createdAt", "")[:10] if card.get("createdAt") else ""],
        ["Prog No:", card.get("progNo", card.get("koNumber", "")), "", "Released by:", card.get("createdBy", "")],
        ["Project Type:", card.get("projType", ""), "", "RM Grade:", card.get("rmGrade", "")],
        ["Part No:", card.get("partNumber", ""), "Mc Category:", card.get("workCenter", ""), "RM Size:", card.get("rmSize", "")],
    ]
    info_table = Table(info_data, colWidths=[40*mm, 80*mm, 30*mm, 35*mm, 45*mm, 45*mm])
    info_table.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTNAME", (3, 0), (3, -1), "Helvetica-Bold"),
        ("FONTNAME", (2, 5), (2, 5), "Helvetica-Bold"),
        ("FONTNAME", (4, 5), (4, 5), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    elements.append(info_table)
    elements.append(Spacer(1, 8*mm))

    # Steps table mirroring Excel format
    steps = card.get("steps", [])
    step_header = [
        "S.N.", "Description of Operation", "Process\nDate", "M/C\nCategory",
        "Opn'r\nSign", "Insp'r\nSign", "Ins\nDate", "Acc Qty",
        "Rej Qty", "Rwk Qty", "Remarks"
    ]
    step_rows = [step_header]
    for idx, s in enumerate(steps, start=1):
        sign_off_at = s.get("signedOffAt")
        date_str = sign_off_at[:10] if sign_off_at else ""
        
        status = s.get("status", "")
        remarks = status
        if status == "Failed":
            remarks = "FAILED: " + str(s.get("deviationReason", ""))

        step_rows.append([
            str(s.get("stepNumber", idx)),
            s.get("operationName", ""),
            date_str,
            s.get("workCenter", ""),
            s.get("signedOffBy", ""),
            "", # Inspector Sign (blank for manual)
            "", # Insp Date
            str(s.get("completionQty", "")),
            "", # Rej Qty
            "", # Rwk Qty
            remarks,
        ])
        
        # Add a blank row for spacing like the Excel template
        step_rows.append(["", "", "", "", "", "", "", "", "", "", ""])

    step_table = Table(step_rows, colWidths=[10*mm, 55*mm, 20*mm, 25*mm, 25*mm, 25*mm, 20*mm, 20*mm, 20*mm, 20*mm, 35*mm])

    step_style = TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#082b63")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.black),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("ALIGN", (1, 1), (1, -1), "LEFT"), # Left align description
    ])
    
    # Merge the blank rows to make them just spacers
    for i in range(2, len(step_rows), 2):
        step_style.add("SPAN", (0, i), (-1, i))
        step_style.add("BACKGROUND", (0, i), (-1, i), colors.HexColor("#f8fafc"))
        step_style.add("TOPPADDING", (0, i), (-1, i), 0)
        step_style.add("BOTTOMPADDING", (0, i), (-1, i), 0)
        
    step_table.setStyle(step_style)
    elements.append(step_table)
    elements.append(Spacer(1, 10*mm))

    doc.build(elements)
    return buf.getvalue()


def _generate_simple_pdf(card: dict) -> bytes:
    """Minimal PDF without reportlab — plain text format."""
    lines = [
        "ASM Technologies Ltd - Digital Manufacturing Traveler",
        "=" * 55,
        f"Card Number : {card.get('cardNumber', '')}",
        f"Job Name    : {card.get('jobName', '')}",
        f"Part Number : {card.get('partNumber', '')} Rev {card.get('partRevision', '')}",
        f"Batch Qty   : {card.get('batchQuantity', '')}",
        f"Work Order  : {card.get('workOrderNumber', '')}",
        f"Status      : {card.get('status', '')}",
        f"Created By  : {card.get('createdBy', '')}",
        "",
        "Operation Steps",
        "-" * 55,
    ]
    for s in card.get("steps", []):
        lines.append(
            f"  Step {s.get('stepNumber', '?'):>3}  |  {s.get('operationName', ''):<28} "
            f"|  {s.get('status', ''):<12} |  {s.get('signedOffBy', '') or '—'}"
        )
    lines.append("")
    lines.append(f"Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}")
    text = "\n".join(lines)

    # Build a minimal valid PDF
    content_stream = f"BT /F1 10 Tf 50 750 Td 12 TL"
    for line in lines:
        safe = line.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
        content_stream += f" ({safe}) '"
    content_stream += " ET"

    objects = []
    objects.append("1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj")
    objects.append("2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj")
    objects.append(
        "3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
        "/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj"
    )
    stream_bytes = content_stream.encode("latin-1")
    objects.append(f"4 0 obj << /Length {len(stream_bytes)} >> stream\n"
                   + content_stream + "\nendstream endobj")
    objects.append(
        "5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Courier >> endobj"
    )

    body = ""
    offsets = []
    header = "%PDF-1.4\n"
    pos = len(header)
    for obj in objects:
        offsets.append(pos)
        obj_str = obj + "\n"
        body += obj_str
        pos += len(obj_str)

    xref_pos = pos
    xref = f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n"
    for off in offsets:
        xref += f"{off:010d} 00000 n \n"
    xref += (
        f"trailer << /Size {len(objects) + 1} /Root 1 0 R >>\n"
        f"startxref\n{xref_pos}\n%%EOF\n"
    )

    return (header + body + xref).encode("latin-1")
