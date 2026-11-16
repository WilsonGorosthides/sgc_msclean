"""Extrai do PDF da marca os PNGs mestres do app (RNF-008, issue #96).

Uso (fora do app; precisa de PyMuPDF e Pillow num ambiente Python à parte):
    python tool/marca/extrair_marca.py docs/Logo_MS_Clean.pdf assets/marca
Depois, regerar ícones e abertura:
    fvm dart run flutter_launcher_icons
    fvm dart run flutter_native_splash:create

A gota é desenhada por cima do M e do S. Para isolá-la, a página é
renderizada e os pixels claros que caem dentro das formas vetoriais do M e do
S (caminhos 33 e 34 do PDF) viram azul-marinho; a gota, ciano, fica.

Gera, a partir da versão de fundo azul-marinho (quadrante superior direito):
- simbolo_fundo.png   1024x1024: a gota com o sofá sobre o azul-marinho (ícone legado e web)
- simbolo_frente.png  1024x1024: a gota com o sofá em fundo transparente, com
                      margem para a zona segura do ícone adaptativo (66/108)
- simbolo_abertura.png 1152x1152: a gota para a abertura do Android 12+ (o
                      sistema mostra só um círculo de 768 px no centro)
- logo_completo.png   o logo inteiro (MS CLEAN + linha de apoio), fundo
                      transparente, 960 px de largura: a abertura trata a
                      imagem como xxxhdpi (4x), então ocupa 240 dp na tela
- cor_fundo.txt       o azul-marinho medido no PDF, em #RRGGBB
"""
import sys

import pymupdf
from PIL import Image, ImageChops, ImageDraw

pdf, saida = sys.argv[1], sys.argv[2]
doc = pymupdf.open(pdf)
pag = doc[0]
ZOOM = 8  # px por ponto
M_SEQ, S_SEQ = 33, 34  # caminhos do M e do S na versão azul-marinho

# recorte da gota (pontos) e do logo completo
GOTA = pymupdf.Rect(1180, 80, 1410, 340)
LOGO = pymupdf.Rect(985, 85, 1545, 470)


def render(clip):
    pix = pag.get_pixmap(matrix=pymupdf.Matrix(ZOOM, ZOOM), clip=clip, alpha=False)
    return Image.frombytes('RGB', (pix.width, pix.height), pix.samples)


ESTRELAS = (40, 41, 42)  # brilhos ciano em volta da gota


def mascara_letras(clip, tamanho, seqs=(M_SEQ, S_SEQ)):
    """Máscara (L) com os caminhos `seqs` preenchidos, na escala do render."""
    img = Image.new('L', tamanho, 0)
    d = ImageDraw.Draw(img)
    for dr in pag.get_drawings():
        if dr['seqno'] not in seqs:
            continue
        # cada subcaminho vira um polígono; curvas são amostradas
        pts = []
        poligonos = []
        for it in dr['items']:
            if it[0] == 'l':
                a, b = it[1], it[2]
                if pts and (abs(pts[-1][0] - a.x) > 0.01 or abs(pts[-1][1] - a.y) > 0.01):
                    poligonos.append(pts)
                    pts = []
                if not pts:
                    pts.append((a.x, a.y))
                pts.append((b.x, b.y))
            elif it[0] == 'c':
                a, c1, c2, b = it[1], it[2], it[3], it[4]
                if pts and (abs(pts[-1][0] - a.x) > 0.01 or abs(pts[-1][1] - a.y) > 0.01):
                    poligonos.append(pts)
                    pts = []
                if not pts:
                    pts.append((a.x, a.y))
                for i in range(1, 17):
                    t = i / 16
                    x = ((1-t)**3*a.x + 3*(1-t)**2*t*c1.x + 3*(1-t)*t**2*c2.x + t**3*b.x)
                    y = ((1-t)**3*a.y + 3*(1-t)**2*t*c1.y + 3*(1-t)*t**2*c2.y + t**3*b.y)
                    pts.append((x, y))
            elif it[0] == 're':
                r = it[1]
                poligonos.append([(r.x0, r.y0), (r.x1, r.y0), (r.x1, r.y1), (r.x0, r.y1)])
        if pts:
            poligonos.append(pts)
        for poli in poligonos:
            px = [((x - clip.x0) * ZOOM, (y - clip.y0) * ZOOM) for x, y in poli]
            if len(px) >= 3:
                d.polygon(px, fill=255)
    # alarga 2 px para pegar a borda suavizada das letras
    from PIL import ImageFilter
    return img.filter(ImageFilter.MaxFilter(5))


def sem_letras(clip):
    img = render(clip)
    fundo = img.getpixel((2, 2))
    masc = mascara_letras(clip, img.size)
    # só o que é claro (letra branca à vista) dentro da forma do M/S vira fundo;
    # a gota, desenhada por cima das letras, é ciano e fica
    lum = img.convert('L').point(lambda v: 255 if v > 150 else 0)
    alvo = ImageChops.multiply(masc, lum)
    # inclui também a borda suavizada entre letra e fundo
    from PIL import ImageFilter
    alvo = alvo.filter(ImageFilter.MaxFilter(3))
    alvo = ImageChops.multiply(alvo, masc)
    img.paste(Image.new('RGB', img.size, fundo), (0, 0), alvo)
    # os brilhos ficam no logo completo; no símbolo, isolado, só poluem
    img.paste(Image.new('RGB', img.size, fundo), (0, 0),
              mascara_letras(clip, img.size, ESTRELAS))
    return img, fundo


def transparente(img, fundo, limiar=60):
    """Fundo azul-marinho vira transparente, com a borda proporcional."""
    rgba = img.convert('RGBA')
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = px[x, y]
            dist = ((r - fundo[0])**2 + (g - fundo[1])**2 + (b - fundo[2])**2) ** 0.5
            a = min(255, int(255 * dist / limiar))
            px[x, y] = (r, g, b, a)
    return rgba


def quadrado(img, lado, ocupacao, fundo_rgba):
    """Centraliza img num quadrado `lado`, ocupando `ocupacao` do lado."""
    caixa = img.getbbox() if img.mode == 'RGBA' else None
    if caixa:
        img = img.crop(caixa)
    escala = (lado * ocupacao) / max(img.size)
    img = img.resize((round(img.width * escala), round(img.height * escala)), Image.LANCZOS)
    tela = Image.new('RGBA', (lado, lado), fundo_rgba)
    tela.alpha_composite(img.convert('RGBA'), ((lado - img.width) // 2, (lado - img.height) // 2))
    return tela


gota, fundo = sem_letras(GOTA)
gota_t = transparente(gota, fundo)

cor = '#%02X%02X%02X' % fundo
open(f'{saida}/cor_fundo.txt', 'w').write(cor + '\n')

# ícone legado / web: a gota ocupa 72% do quadrado, sobre o azul-marinho
quadrado(gota_t, 1024, 0.72, fundo + (255,)).convert('RGB').save(f'{saida}/simbolo_fundo.png')
# ícone adaptativo: a gota cabe na zona segura (66/108 ~ 61%); 56% com folga
quadrado(gota_t, 1024, 0.56, (0, 0, 0, 0)).save(f'{saida}/simbolo_frente.png')

# abertura do Android 12+: círculo visível de 768 em 1152; a gota cabe com folga
quadrado(gota_t, 1152, 0.45, (0, 0, 0, 0)).save(f'{saida}/simbolo_abertura.png')

logo = render(LOGO)
logo_t = transparente(logo, fundo)
logo_t = logo_t.crop(logo_t.getbbox())
largura = 960
logo_t = logo_t.resize((largura, round(logo_t.height * largura / logo_t.width)), Image.LANCZOS)
logo_t.save(f'{saida}/logo_completo.png')
print('fundo', cor, 'gota', gota.size, 'logo', logo.size)
