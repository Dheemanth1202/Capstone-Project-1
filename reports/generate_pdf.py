import os
import re
import subprocess

def md_to_html(md_content):
    lines = md_content.split('\n')
    html_lines = []
    
    in_code_block = False
    in_list = False
    in_table = False
    table_headers = []
    table_alignments = []
    
    for line in lines:
        stripped = line.strip()
        
        # Code block handling
        if stripped.startswith('```'):
            if in_code_block:
                html_lines.append('</code></pre>')
                in_code_block = False
            else:
                lang = stripped[3:].strip()
                html_lines.append(f'<pre><code class="language-{lang}">')
                in_code_block = True
            continue
            
        if in_code_block:
            # Escape HTML characters inside code blocks
            escaped = line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            html_lines.append(escaped)
            continue
            
        # Horizontal rules
        if stripped == '---':
            html_lines.append('<hr>')
            continue
            
        # Table handling
        if stripped.startswith('|'):
            cells = [c.strip() for c in stripped.split('|')[1:-1]]
            
            if not in_table:
                in_table = True
                table_headers = cells
                continue
                
            # Alignment row separator Check (e.g. | :--- | :--- |)
            if all(re.match(r'^:?-+:?$', c) for c in cells):
                table_alignments = []
                for c in cells:
                    if c.startswith(':') and c.endswith(':'):
                        table_alignments.append('center')
                    elif c.endswith(':'):
                        table_alignments.append('right')
                    else:
                        table_alignments.append('left')
                
                # Write the header now
                html_lines.append('<table><thead><tr>')
                for i, h in enumerate(table_headers):
                    align = table_alignments[i] if i < len(table_alignments) else 'left'
                    html_lines.append(f'<th style="text-align: {align};">{h}</th>')
                html_lines.append('</tr></thead><tbody>')
                continue
                
            # Regular table row
            html_lines.append('<tr>')
            for i, c in enumerate(cells):
                align = table_alignments[i] if i < len(table_alignments) else 'left'
                # Format cells
                formatted_cell = format_inline_markdown(c)
                html_lines.append(f'<td style="text-align: {align};">{formatted_cell}</td>')
            html_lines.append('</tr>')
            continue
        else:
            if in_table:
                html_lines.append('</tbody></table>')
                in_table = False
                table_headers = []
                table_alignments = []
                
        # List handling
        if stripped.startswith('* ') or stripped.startswith('- '):
            if not in_list:
                html_lines.append('<ul>')
                in_list = True
            content = format_inline_markdown(stripped[2:])
            html_lines.append(f'<li>{content}</li>')
            continue
        else:
            if in_list:
                html_lines.append('</ul>')
                in_list = False
                
        # Headings
        if stripped.startswith('# '):
            content = format_inline_markdown(stripped[2:])
            html_lines.append(f'<h1>{content}</h1>')
        elif stripped.startswith('## '):
            content = format_inline_markdown(stripped[3:])
            html_lines.append(f'<h2>{content}</h2>')
        elif stripped.startswith('### '):
            content = format_inline_markdown(stripped[4:])
            html_lines.append(f'<h3>{content}</h3>')
        elif stripped.startswith('#### '):
            content = format_inline_markdown(stripped[5:])
            html_lines.append(f'<h4>{content}</h4>')
        elif stripped:
            content = format_inline_markdown(stripped)
            html_lines.append(f'<p>{content}</p>')
        else:
            html_lines.append('<br>')
            
    return '\n'.join(html_lines)

def format_inline_markdown(text):
    # Escape some basic HTML characters (except tags we generate)
    text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    
    # Restoring html elements if we need them, but here it's simple
    # Bold: **text**
    text = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', text)
    # Inline code: `code`
    text = re.sub(r'`(.*?)`', r'<code>\1</code>', text)
    # Markdown links: [text](url)
    text = re.sub(r'\[(.*?)\]\((.*?)\)', r'<a href="\2">\1</a>', text)
    # LaTeX inline math mapping: e.g. $O(N)$ to <em>O(N)</em>
    text = re.sub(r'\$(.*?)\$', r'<span class="math">\1</span>', text)
    
    return text

def main():
    report_md_path = 'reports/wallace_report.md'
    output_html_path = 'reports/wallace_report.html'
    output_pdf_path = 'reports/wallace_report.pdf'
    
    if not os.path.exists(report_md_path):
        print(f"Error: {report_md_path} does not exist.")
        return
        
    with open(report_md_path, 'r', encoding='utf-8') as f:
        md_content = f.read()
        
    html_body = md_to_html(md_content)
    
    # Premium stylesheet to make the PDF look amazing
    html_template = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Pipelined Wallace Tree Multiplier Report</title>
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    
    body {{
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        color: #1e293b;
        line-height: 1.6;
        font-size: 14px;
        margin: 0;
        padding: 40px;
        background-color: #ffffff;
    }}
    
    h1, h2, h3, h4 {{
        color: #0f172a;
        font-weight: 700;
        margin-top: 1.5em;
        margin-bottom: 0.5em;
        page-break-after: avoid;
    }}
    
    h1 {{
        font-size: 26px;
        border-bottom: 2px solid #e2e8f0;
        padding-bottom: 10px;
        margin-top: 0;
    }}
    
    h2 {{
        font-size: 20px;
        border-bottom: 1px solid #f1f5f9;
        padding-bottom: 6px;
    }}
    
    h3 {{ font-size: 16px; }}
    h4 {{ font-size: 14px; }}
    
    p {{
        margin-top: 0;
        margin-bottom: 1em;
    }}
    
    hr {{
        border: 0;
        border-top: 1px solid #e2e8f0;
        margin: 30px 0;
    }}
    
    ul {{
        margin-top: 0;
        margin-bottom: 1em;
        padding-left: 20px;
    }}
    
    li {{
        margin-bottom: 0.25em;
    }}
    
    code {{
        font-family: Consolas, Monaco, "Andale Mono", monospace;
        background-color: #f1f5f9;
        padding: 2px 6px;
        border-radius: 4px;
        font-size: 12px;
        color: #0f172a;
    }}
    
    pre {{
        background-color: #0f172a;
        color: #f8fafc;
        padding: 16px;
        border-radius: 8px;
        overflow-x: auto;
        margin-top: 0;
        margin-bottom: 1.5em;
    }}
    
    pre code {{
        background-color: transparent;
        padding: 0;
        border-radius: 0;
        color: inherit;
        font-size: 12px;
    }}
    
    table {{
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 1.5em;
        font-size: 13px;
    }}
    
    th, td {{
        padding: 10px 12px;
        border-bottom: 1px solid #e2e8f0;
    }}
    
    th {{
        background-color: #f8fafc;
        font-weight: 600;
        color: #334155;
    }}
    
    tr:nth-child(even) td {{
        background-color: #fafafa;
    }}
    
    a {{
        color: #2563eb;
        text-decoration: none;
    }}
    
    a:hover {{
        text-decoration: underline;
    }}
    
    .math {{
        font-family: "Cambria Math", "Times New Roman", serif;
        font-style: italic;
    }}
    
    /* Cover Page styling */
    .cover-page {{
        height: 100vh;
        display: flex;
        flex-direction: column;
        justify-content: center;
        page-break-after: always;
    }}
    
    @media print {{
        body {{
            padding: 20px;
        }}
        .page-break {{
            page-break-before: always;
        }}
    }}
</style>
</head>
<body>
    {html_body}
</body>
</html>
"""
    
    # Save the generated HTML
    with open(output_html_path, 'w', encoding='utf-8') as f:
        f.write(html_template)
        
    print(f"HTML file generated successfully: {output_html_path}")
    
    # Execute MS Edge to convert HTML to PDF
    msedge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    abs_html_path = os.path.abspath(output_html_path)
    abs_pdf_path = os.path.abspath(output_pdf_path)
    
    cmd = [
        msedge_path,
        '--headless',
        '--disable-gpu',
        f'--print-to-pdf={abs_pdf_path}',
        abs_html_path
    ]
    
    print("Running Edge PDF Generation...")
    try:
        subprocess.run(cmd, check=True)
        print(f"PDF generated successfully: {output_pdf_path}")
    except Exception as e:
        print(f"Error printing to PDF: {e}")

if __name__ == '__main__':
    main()
