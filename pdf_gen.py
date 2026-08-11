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
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import mm
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
    import qrcode

    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, topMargin=20*mm, bottomMargin=20*mm,
                            leftMargin=15*mm, rightMargin=15*mm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("TravelerTitle", parent=styles["Title"],
                                  fontSize=18, textColor=colors.HexColor("#082b63"))
    subtitle_style = ParagraphStyle("Sub", parent=styles["Normal"],
                                     fontSize=10, textColor=colors.grey)

    elements = []

    # Header
    header_data = []
    
    title_paragraphs = [
        Paragraph("ASM Technologies Ltd", title_style),
        Paragraph("Digital Manufacturing Traveler / Route Card", subtitle_style)
    ]
    
    # Generate QR Code for Work Order (Deep link to the app)
    qr_img = None
    wo_num = card.get("workOrderNumber", "")
    card_id = card.get("id", "")
    if card_id:
        # Create a deep link to the specific route card in the web app
        qr_url = f"https://mzvez-125-18-71-132.run.pinggy-free.link/#/card-detail?id={card_id}"
        qr = qrcode.QRCode(version=1, box_size=10, border=1)
        qr.add_data(qr_url)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        qr_buf = io.BytesIO()
        img.save(qr_buf, format="PNG")
        qr_buf.seek(0)
        qr_img = Image(qr_buf, width=20*mm, height=20*mm)

    if qr_img:
        header_table = Table([[title_paragraphs, qr_img]], colWidths=[140*mm, 30*mm])
        header_table.setStyle(TableStyle([
            ('ALIGN', (1, 0), (1, 0), 'RIGHT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ]))
        elements.append(header_table)
    else:
        elements.extend(title_paragraphs)

    elements.append(Spacer(1, 8*mm))

    # Card info table
    info_data = [
        ["Card Number", card.get("cardNumber", "—"), "Status", card.get("status", "—")],
        ["Job Name", card.get("jobName", "—"), "Work Order", card.get("workOrderNumber", "—")],
        ["Part Number", card.get("partNumber", "—"), "Revision", card.get("partRevision", "—")],
        ["Batch Qty", str(card.get("batchQuantity", "—")), "Created By", card.get("createdBy", "—")],
        ["Created At", card.get("createdAt", "—")[:10], "Notes", card.get("notes", "—") or "—"],
    ]
    info_table = Table(info_data, colWidths=[30*mm, 55*mm, 30*mm, 55*mm])
    info_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#e8edf5")),
        ("BACKGROUND", (2, 0), (2, -1), colors.HexColor("#e8edf5")),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#cbd5e1")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    elements.append(info_table)
    elements.append(Spacer(1, 6*mm))

    # Steps table
    elements.append(Paragraph("Operation Steps", styles["Heading2"]))
    steps = card.get("steps", [])
    step_header = ["#", "Operation", "Work Center", "Status", "Signed Off By", "Date"]
    step_rows = [step_header]
    for s in steps:
        step_rows.append([
            str(s.get("stepNumber", "")),
            s.get("operationName", ""),
            s.get("workCenter", ""),
            s.get("status", ""),
            s.get("signedOffBy", "") or "—",
            (s.get("signedOffAt", "") or "—")[:10],
        ])
    step_table = Table(step_rows, colWidths=[12*mm, 45*mm, 25*mm, 25*mm, 35*mm, 28*mm])

    step_style = [
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#082b63")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#cbd5e1")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]
    for i, s in enumerate(steps, start=1):
        status = s.get("status", "")
        if status == "Completed":
            step_style.append(("BACKGROUND", (3, i), (3, i), colors.HexColor("#d1fae5")))
        elif status == "Deviated":
            step_style.append(("BACKGROUND", (3, i), (3, i), colors.HexColor("#fee2e2")))
        elif status == "In Progress":
            step_style.append(("BACKGROUND", (3, i), (3, i), colors.HexColor("#dbeafe")))

    step_table.setStyle(TableStyle(step_style))
    elements.append(step_table)
    elements.append(Spacer(1, 10*mm))

    # Footer
    elements.append(Paragraph(
        f"Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')} | "
        "ASM Technologies Ltd — Confidential",
        subtitle_style))

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
