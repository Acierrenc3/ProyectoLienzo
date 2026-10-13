# generar_modelos.py — Modelos 3D originales de Contratiempo (low-poly, estilo sencillo).
# Genera OBJ + MTL (centímetros, eje Y hacia arriba, el modelo mira hacia +Z) en Assets/Modelos/.
# Uso: python3 tools/generar_modelos.py [carpeta_salida]
# Personajes: Oria, Joel, Kesh (héroes) y Metrónomo Roto, Soprano Hueca (jefes).
import math, os, sys
import numpy as np

# ---------------------------------------------------------------- utilidades
def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])

def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])

def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])

def frame_from_dir(d):
    """Matriz que lleva el eje +Y local a la dirección d."""
    d = np.asarray(d, float); d = d / np.linalg.norm(d)
    up = np.array([0.0, 1.0, 0.0])
    if abs(np.dot(d, up)) > 0.999:
        return np.eye(3) if d[1] > 0 else rot_x(math.pi)
    x = np.cross(up, d); x /= np.linalg.norm(x)
    z = np.cross(x, d)
    return np.column_stack([x, d, z])


class Part:
    def __init__(self, verts, faces, mat):
        self.v = np.asarray(verts, float)
        self.f = [tuple(f) for f in faces]
        self.mat = mat

    def apply(self, m=None, t=(0, 0, 0), s=None):
        v = self.v
        if s is not None:
            v = v * np.asarray(s, float)
        if m is not None:
            v = v @ np.asarray(m).T
        self.v = v + np.asarray(t, float)
        return self


def lathe(profile, mat, segs=16, cap_bottom=True, cap_top=True, phase=0.0):
    """profile: lista de (radio, altura) de abajo arriba. Gira alrededor del eje Y."""
    verts, faces = [], []
    rings = len(profile)
    for (r, y) in profile:
        for i in range(segs):
            a = 2 * math.pi * i / segs + phase
            verts.append((r * math.cos(a), y, r * math.sin(a)))
    for j in range(rings - 1):
        for i in range(segs):
            a = j * segs + i
            b = j * segs + (i + 1) % segs
            c = (j + 1) * segs + (i + 1) % segs
            d = (j + 1) * segs + i
            faces.append((a, d, c, b))
    if cap_bottom and profile[0][0] > 0.01:
        verts.append((0, profile[0][1], 0)); ci = len(verts) - 1
        for i in range(segs):
            faces.append((ci, i, (i + 1) % segs))
    if cap_top and profile[-1][0] > 0.01:
        verts.append((0, profile[-1][1], 0)); ci = len(verts) - 1
        base = (rings - 1) * segs
        for i in range(segs):
            faces.append((ci, base + (i + 1) % segs, base + i))
    return Part(verts, faces, mat)


def sphere(r, mat, segs=12, rings=8, center=(0, 0, 0), s=(1, 1, 1)):
    prof = []
    for j in range(rings + 1):
        t = math.pi * j / rings - math.pi / 2
        prof.append((r * math.cos(t), r * math.sin(t)))
    p = lathe(prof, mat, segs, cap_bottom=False, cap_top=False)
    return p.apply(s=s, t=center)


def cylinder(p0, p1, r0, mat, r1=None, segs=10):
    p0, p1 = np.asarray(p0, float), np.asarray(p1, float)
    r1 = r0 if r1 is None else r1
    h = np.linalg.norm(p1 - p0)
    p = lathe([(r0, 0), (r1, h)], mat, segs)
    return p.apply(m=frame_from_dir(p1 - p0), t=p0)


def box(center, size, mat, m=None):
    sx, sy, sz = [x / 2 for x in size]
    v = [(-sx, -sy, -sz), (sx, -sy, -sz), (sx, sy, -sz), (-sx, sy, -sz),
         (-sx, -sy, sz), (sx, -sy, sz), (sx, sy, sz), (-sx, sy, sz)]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6), (1, 2, 6, 5), (0, 4, 7, 3)]
    return Part(v, f, mat).apply(m=m, t=center)


def torus(R, r, mat, segs=16, tube=6):
    verts, faces = [], []
    for i in range(segs):
        a = 2 * math.pi * i / segs
        for j in range(tube):
            b = 2 * math.pi * j / tube
            x = (R + r * math.cos(b)) * math.cos(a)
            z = (R + r * math.cos(b)) * math.sin(a)
            y = r * math.sin(b)
            verts.append((x, y, z))
    for i in range(segs):
        for j in range(tube):
            a = i * tube + j
            b = ((i + 1) % segs) * tube + j
            c = ((i + 1) % segs) * tube + (j + 1) % tube
            d = i * tube + (j + 1) % tube
            faces.append((a, b, c, d))
    return Part(verts, faces, mat)


def bell(height, mat, segs=14):
    """Campana: perfil clásico con boca abierta (sin tapa abajo)."""
    h = height
    prof = [(0.62 * h, 0.0), (0.58 * h, 0.06 * h), (0.47 * h, 0.22 * h), (0.40 * h, 0.45 * h),
            (0.36 * h, 0.70 * h), (0.30 * h, 0.88 * h), (0.18 * h, 0.98 * h), (0.02, h)]
    return lathe(prof, mat, segs, cap_bottom=False, cap_top=False)


class Model:
    def __init__(self, name):
        self.name = name
        self.parts = []
        self.materials = {}

    def mat(self, name, rgb, emissive=False):
        self.materials[name] = (rgb, emissive)
        return name

    def add(self, *parts):
        self.parts.extend(parts)

    def bounds(self):
        allv = np.vstack([p.v for p in self.parts])
        return allv.min(0), allv.max(0)

    def tri_count(self):
        n = 0
        for p in self.parts:
            for f in p.f:
                n += len(f) - 2
        return n

    def ground(self):
        lo, hi = self.bounds()
        for p in self.parts:
            p.v[:, 1] -= lo[1]

    def save(self, folder):
        os.makedirs(folder, exist_ok=True)
        obj = os.path.join(folder, self.name + ".obj")
        mtl = os.path.join(folder, self.name + ".mtl")
        with open(mtl, "w") as fm:
            for name, (rgb, em) in self.materials.items():
                fm.write(f"newmtl {self.name}_{name}\n")
                fm.write("Kd {:.3f} {:.3f} {:.3f}\n".format(*rgb))
                fm.write("Ka 0 0 0\nKs 0.05 0.05 0.05\nNs 10\nd 1\nillum 2\n")
                if em:
                    fm.write("Ke {:.3f} {:.3f} {:.3f}\n".format(*rgb))
                fm.write("\n")
        with open(obj, "w") as fo:
            fo.write(f"# Contratiempo — {self.name} (generado por tools/generar_modelos.py)\n")
            fo.write(f"mtllib {self.name}.mtl\no {self.name}\n")
            offset = 1
            by_mat = {}
            for p in self.parts:
                for v in p.v:
                    # Ejes para UEFN: el importador OBJ toma el archivo como Z arriba.
                    # Escribimos (adelante, lado, alto) para que quede X adelante y Z arriba.
                    fo.write("v {:.2f} {:.2f} {:.2f}\n".format(v[2], v[0], v[1]))
                by_mat.setdefault(p.mat, []).append((p, offset))
                offset += len(p.v)
            for mat, lst in by_mat.items():
                fo.write(f"usemtl {self.name}_{mat}\n")
                for p, off in lst:
                    for f in p.f:
                        fo.write("f " + " ".join(str(i + off) for i in f) + "\n")
        return obj


def limb(model, a, b, r, mat, r2=None, joint=True):
    model.add(cylinder(a, b, r, mat, r2, segs=8))
    if joint:
        model.add(sphere((r2 or r) * 1.05, mat, 8, 5, center=b))

# ---------------------------------------------------------------- héroes
SKIN = (0.93, 0.74, 0.60)


def humanoid(m, coat, coat_profile, skin, hair, boots, height=170.0, arm_pose=None):
    """Cuerpo base estilizado (cabeza grande). Devuelve puntos útiles."""
    k = height / 170.0
    m.add(lathe([(rr * k, yy * k) for rr, yy in coat_profile], coat, 14))
    # piernas y botas
    for sx in (-1, 1):
        m.add(cylinder((sx * 9 * k, 0, 0), (sx * 9 * k, 45 * k, 0), 6.5 * k, boots, 7 * k, segs=8))
        m.add(box((sx * 9 * k, 4 * k, 4 * k), (14 * k, 8 * k, 20 * k), boots))
    # cabeza
    head_c = (0, 140 * k, 0)
    m.add(sphere(22 * k, skin, 14, 10, center=head_c, s=(1, 1.05, 1)))
    # ojos
    for sx in (-1, 1):
        m.add(sphere(3 * k, "ojos", 6, 4, center=(sx * 8 * k, 142 * k, 19.5 * k), s=(1, 1.3, 0.6)))
    # hombros y brazos
    sh_l, sh_r = np.array((-24 * k, 108 * k, 0)), np.array((24 * k, 108 * k, 0))
    pose = arm_pose or {}
    el_l = np.array(pose.get("el_l", (-30 * k, 82 * k, 4 * k)))
    ha_l = np.array(pose.get("ha_l", (-32 * k, 60 * k, 10 * k)))
    el_r = np.array(pose.get("el_r", (30 * k, 82 * k, 4 * k)))
    ha_r = np.array(pose.get("ha_r", (32 * k, 60 * k, 10 * k)))
    for sh, el, ha in ((sh_l, el_l, ha_l), (sh_r, el_r, ha_r)):
        m.add(sphere(8 * k, coat, 8, 6, center=sh))
        limb(m, sh, el, 6 * k, coat)
        limb(m, el, ha, 5 * k, coat, 4.5 * k)
        m.add(sphere(5.5 * k, skin, 8, 6, center=ha))
    return {"head": np.array(head_c), "ha_l": ha_l, "ha_r": ha_r, "k": k}


def make_oria():
    m = Model("Oria")
    coat = m.mat("tunica", (0.85, 0.30, 0.18))
    m.mat("piel", SKIN); m.mat("ojos", (0.12, 0.10, 0.10))
    hair = m.mat("pelo", (0.55, 0.12, 0.10))
    boots = m.mat("botas", (0.30, 0.20, 0.14))
    wood = m.mat("madera", (0.55, 0.36, 0.20))
    skinm = m.mat("parche", (0.95, 0.90, 0.78))
    gold = m.mat("laton", (0.90, 0.70, 0.25))
    prof = [(16, 40), (19, 48), (24, 62), (20, 80), (22, 100), (25, 110), (14, 118), (8, 120)]
    pts = humanoid(m, coat, prof, "piel", hair, boots,
                   arm_pose={"el_r": (34, 92, 14), "ha_r": (30, 112, 26)})
    k = pts["k"]
    # pelo: casquete + coleta
    m.add(sphere(23.5, hair, 14, 8, center=(0, 146, -3), s=(1.02, 0.85, 1.02)))
    m.add(sphere(9, hair, 8, 6, center=(0, 150, -24)))
    m.add(cylinder((0, 148, -26), (0, 118, -34), 6, hair, 3, segs=8))
    # cinturón
    m.add(torus(21, 2.2, gold, 16, 5).apply(t=(0, 78, 0)))
    # martillo-tambor en la mano derecha
    hand = pts["ha_r"]
    top = hand + np.array((4, 60, 6))
    m.add(cylinder(hand + np.array((-2, -22, -2)), top, 2.8, wood, segs=8))
    d_axis = np.array((1, 0, 0))
    drum_c = top + np.array((0, 8, 0))
    m.add(cylinder(drum_c - d_axis * 16, drum_c + d_axis * 16, 13, coat, segs=14))
    for sx in (-1, 1):
        m.add(cylinder(drum_c + d_axis * sx * 16, drum_c + d_axis * sx * 16.8, 13.2, skinm, segs=14))
        m.add(torus(13.5, 1.6, gold, 14, 5).apply(m=rot_z(math.pi / 2), t=drum_c + d_axis * sx * 15.5))
    m.ground()
    return m


def make_joel():
    m = Model("Joel")
    coat = m.mat("abrigo", (0.16, 0.45, 0.50))
    m.mat("piel", (0.80, 0.60, 0.45)); m.mat("ojos", (0.10, 0.10, 0.12))
    hair = m.mat("pelo", (0.15, 0.12, 0.10))
    boots = m.mat("botas", (0.18, 0.16, 0.16))
    gold = m.mat("diapason", (0.95, 0.78, 0.30))
    hat = m.mat("sombrero", (0.22, 0.20, 0.26))
    prof = [(24, 30), (22, 50), (18, 75), (19, 95), (23, 108), (12, 118), (8, 121)]
    pts = humanoid(m, coat, prof, "piel", hair, boots, height=178,
                   arm_pose={"el_l": (-36, 84, 6), "ha_l": (-40, 70, 18)})
    k = pts["k"]
    # sombrero de copa baja
    hc = pts["head"] + np.array((0, 20 * k, 0))
    m.add(cylinder(hc + np.array((0, -2, 0)), hc + np.array((0, 0.5, 0)), 30 * k, hat, segs=16))
    m.add(cylinder(hc, hc + np.array((0, 18 * k, 0)), 18 * k, hat, 16 * k, segs=14))
    m.add(torus(18 * k, 1.5, gold, 14, 4).apply(t=hc + np.array((0, 3, 0))))
    # gafas redondas
    for sx in (-1, 1):
        m.add(torus(4.8, 0.8, gold, 10, 4).apply(m=rot_x(math.pi / 2), t=(sx * 8.5 * k, 145 * k, 21 * k)))
    # diapasón gigante como bastón (mano izquierda)
    hand = pts["ha_l"]
    base = hand + np.array((0, -62, 0))
    neck = hand + np.array((0, 40, 0))
    m.add(cylinder(base, neck, 2.5, gold, segs=8))
    m.add(sphere(4, gold, 8, 6, center=base))
    fork_base = neck + np.array((0, 6, 0))
    m.add(box(fork_base, (22, 6, 5), gold))
    for sx in (-1, 1):
        m.add(box(fork_base + np.array((sx * 9, 28, 0)), (4.5, 52, 4.5), gold))
    m.ground()
    return m


def make_kesh():
    m = Model("Kesh")
    cloak = m.mat("capa", (0.36, 0.30, 0.45))
    inner = m.mat("sombra", (0.05, 0.04, 0.07))
    eyes = m.mat("ojos_brillo", (0.65, 0.85, 1.0), emissive=True)
    bronze = m.mat("bronce", (0.68, 0.45, 0.22))
    trim = m.mat("ribete", (0.75, 0.75, 0.82))
    # capa larga en forma de campana
    m.add(lathe([(38, 0), (34, 10), (28, 50), (22, 90), (21, 110), (16, 120), (6, 124)], cloak, 16))
    m.add(torus(36, 2.0, trim, 18, 4).apply(t=(0, 4, 0)))
    # capucha
    m.add(sphere(27, cloak, 14, 10, center=(0, 138, -2), s=(1, 1.1, 1.05)))
    m.add(cylinder((0, 160, -14), (0, 176, -26), 9, cloak, 2, segs=10))  # punta de la capucha
    # cara en sombra y ojos brillantes
    m.add(sphere(19, inner, 12, 8, center=(0, 136, 10), s=(1, 1.05, 0.7)))
    for sx in (-1, 1):
        m.add(sphere(2.6, eyes, 6, 4, center=(sx * 7, 138, 23), s=(1.3, 0.8, 0.5)))
    # brazos ocultos: mangas anchas
    for sx in (-1, 1):
        m.add(cylinder((sx * 22, 108, 0), (sx * 34, 70, 14), 8, cloak, 12, segs=10))
        m.add(sphere(6, inner, 8, 6, center=(sx * 35, 66, 16)))
    # cordón con campanillas rotas
    m.add(torus(24, 1.2, trim, 18, 4).apply(t=(0, 84, 0)))
    for i, a in enumerate((-0.9, -0.3, 0.35, 1.0)):
        x, z = 24 * math.sin(a), 24 * math.cos(a)
        b = bell(10 - i % 2 * 2, bronze, 10).apply(t=(x, 70 - i % 2 * 4, z + 1))
        b.v[b.v[:, 0] > x + 3] *= np.array((1, 0.92, 1))  # grieta: borde torcido
        m.add(b, cylinder((x, 84, z), (x, 80 - i % 2 * 4, z + 1), 0.6, trim, segs=4))
    # campanilla en la mano derecha
    m.add(bell(14, bronze, 12).apply(m=rot_z(0.4), t=(37, 50, 18)))
    m.ground()
    return m

# ---------------------------------------------------------------- jefes
def make_metronomo():
    m = Model("MetronomoRoto")
    wood = m.mat("madera", (0.40, 0.24, 0.14))
    dark = m.mat("madera_oscura", (0.22, 0.13, 0.08))
    brass = m.mat("laton", (0.85, 0.65, 0.22))
    face = m.mat("esfera", (0.92, 0.88, 0.75))
    eyes = m.mat("ojos_brillo", (1.0, 0.35, 0.15), emissive=True)
    stone = m.mat("piedra", (0.55, 0.55, 0.58))
    # cuerpo: pirámide truncada (4 lados)
    body = lathe([(150, 0), (150, 25), (125, 40), (55, 330), (40, 345)], wood, 4, phase=math.pi / 4)
    m.add(body)
    m.add(lathe([(165, -1), (165, 26)], dark, 4, phase=math.pi / 4))
    # cara frontal (placa) con escala
    m.add(box((0, 170, 72), (120, 210, 6), face, m=rot_x(-math.atan2(95, 290))))
    for i in range(7):
        y = 100 + i * 28
        w = 70 - i * 7
        m.add(box((0, y, 77 - i * 3), (w, 3, 3), dark, m=rot_x(-math.atan2(95, 290))))
    # ojos (agujeros brillantes) y grieta
    for sx in (-1, 1):
        m.add(sphere(12, eyes, 8, 6, center=(sx * 28, 255, 48), s=(1, 0.6, 0.4)))
    m.add(box((22, 200, 66), (6, 120, 4), dark, m=rot_z(0.35) @ rot_x(-0.3)))
    # péndulo: barra + pesa, inclinado (está "roto")
    piv = np.array((0, 300, 60))
    tip = piv + np.array((90, -230, 25))
    m.add(cylinder(piv, tip, 6, brass, segs=8))
    m.add(box(piv + (tip - piv) * 0.55, (46, 30, 22), brass, m=rot_z(math.atan2(90, 230))))
    m.add(sphere(12, brass, 10, 8, center=piv))
    # patas de piedra
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.add(cylinder((sx * 110, -40, sz * 110), (sx * 110, 5, sz * 110), 28, stone, 22, segs=8))
    # brazos con mazas (para golpear)
    for sx in (-1, 1):
        sh = np.array((sx * 95, 220, 0))
        el = sh + np.array((sx * 70, -40, 40))
        ha = el + np.array((sx * 10, -70, 30))
        limb(m, sh, el, 14, dark)
        limb(m, el, ha, 12, dark)
        m.add(sphere(30, brass, 10, 8, center=ha, s=(1, 0.8, 1)))
    m.ground()
    return m


def make_soprano():
    m = Model("SopranoHueca")
    stone = m.mat("piedra", (0.62, 0.62, 0.66))
    dark = m.mat("piedra_oscura", (0.30, 0.30, 0.34))
    void = m.mat("vacio", (0.03, 0.03, 0.05))
    glow = m.mat("brillo", (0.75, 0.55, 1.0), emissive=True)
    bronze = m.mat("bronce", (0.60, 0.42, 0.25))
    # falda-campana gigante
    m.add(bell(260, stone, 18))
    m.add(torus(158, 8, dark, 20, 5).apply(t=(0, 6, 0)))
    # torso
    m.add(lathe([(55, 240), (48, 280), (55, 320), (38, 350), (18, 365)], stone, 14))
    # cabeza con boca abierta (hueca)
    m.add(sphere(42, stone, 14, 10, center=(0, 405, 0), s=(0.9, 1.15, 0.95)))
    m.add(sphere(16, void, 10, 8, center=(0, 388, 34), s=(1, 1.4, 0.5)))
    for sx in (-1, 1):
        m.add(sphere(7, glow, 8, 6, center=(sx * 15, 418, 33), s=(1.2, 0.7, 0.5)))
    # corona de esquirlas de campana
    for i in range(7):
        a = 2 * math.pi * i / 7
        base = np.array((30 * math.cos(a), 448, 30 * math.sin(a)))
        tip = base + np.array((18 * math.cos(a), 45 + (i % 2) * 20, 18 * math.sin(a)))
        m.add(cylinder(base, tip, 9, bronze, 1, segs=4))
    # brazos alzados (cantando)
    for sx in (-1, 1):
        sh = np.array((sx * 55, 340, 0))
        el = sh + np.array((sx * 70, 40, 30))
        ha = el + np.array((sx * 30, 80, 20))
        m.add(sphere(20, stone, 10, 8, center=sh))
        limb(m, sh, el, 16, stone, 13)
        limb(m, el, ha, 13, stone, 10)
        m.add(sphere(16, dark, 10, 8, center=ha, s=(1, 1.3, 0.7)))
    # ondas de sonido (anillos brillantes delante de la boca)
    for i, r in enumerate((26, 40, 56)):
        m.add(torus(r, 2.5, glow, 18, 4).apply(m=rot_x(math.pi / 2), t=(0, 390, 70 + i * 30)))
    m.ground()
    return m


# ---------------------------------------------------------------- armas (espadas musicales originales)
def tube(points, r, mat, segs=8, r_end=None):
    """Tubo que sigue una polilínea (con radio que puede ir cambiando)."""
    pts = [np.asarray(p, float) for p in points]
    parts = []
    n = len(pts) - 1
    for i in range(n):
        ra = r + ((r_end if r_end is not None else r) - r) * i / n
        rb = r + ((r_end if r_end is not None else r) - r) * (i + 1) / n
        parts.append(cylinder(pts[i], pts[i + 1], ra, mat, rb, segs))
        parts.append(sphere(rb, mat, segs, 4, center=pts[i + 1]))
    return parts


def blade(length, width, mat, thick=0.22, tip=0.18, segs=4):
    """Hoja de sección romboidal, a lo largo de +Y, que se afila en la punta."""
    w = width / 2
    p = lathe([(w * 0.9, 0), (w, length * 0.1), (w * 0.95, length * (1 - tip)), (0.5, length)], mat, segs,
              phase=math.pi / 4 if segs == 4 else 0)
    p.v[:, 2] *= thick
    return p


def hilt(m, grip_len, grip_mat, pommel_mat, r=3.2):
    m.add(cylinder((0, -grip_len, 0), (0, 0, 0), r, grip_mat, segs=8))
    for i in range(4):  # cinta del mango
        m.add(torus(r * 1.05, 0.6, pommel_mat, 8, 4).apply(t=(0, -grip_len * (0.2 + 0.2 * i), 0)))


def clef_curve():
    """Clave de sol estilizada (2D, en el plano XY), en cm."""
    pts = []
    for i in range(30):  # espiral inferior
        a = 2.6 * math.pi * i / 29
        rr = 3 + 9 * i / 29
        pts.append((rr * math.cos(a + math.pi), 14 + rr * math.sin(a + math.pi)))
    pts += [(10, 22), (6, 32), (-4, 40), (-7, 50), (-2, 58), (3, 54), (2, 44), (-1, 30), (-3, 12), (-2, 0), (2, -6), (0, -10)]
    return [(x, y, 0) for x, y in pts]


def make_clave_sol():
    m = Model("Espada_ClaveDeSol")
    steel = m.mat("hoja", (0.80, 0.84, 0.92))
    gold = m.mat("oro", (0.95, 0.75, 0.25))
    grip = m.mat("mango", (0.40, 0.10, 0.18))
    glow = m.mat("brillo", (1.0, 0.85, 0.40), emissive=True)
    hilt(m, 26, grip, gold)
    m.add(sphere(5, gold, 10, 6, center=(0, -29, 0)))
    m.add(*tube([(x * 1.2, y * 0.9 - 8, z) for x, y, z in clef_curve()], 1.8, gold, 6))
    m.add(blade(95, 11, steel).apply(t=(0, 40, 0)))
    m.add(box((0, 85, 1.3), (1.2, 80, 0.6), glow))  # acanaladura brillante
    m.ground()
    return m


def make_corchea():
    m = Model("Espada_Corchea")
    steel = m.mat("hoja", (0.22, 0.22, 0.28))
    silver = m.mat("plata", (0.85, 0.86, 0.90))
    grip = m.mat("mango", (0.12, 0.12, 0.16))
    glow = m.mat("brillo", (0.55, 0.85, 1.0), emissive=True)
    hilt(m, 24, grip, silver)
    # cabeza de nota como pomo
    m.add(sphere(10, steel, 12, 8, center=(-6, -32, 0), s=(1.3, 0.85, 0.7)).apply(m=rot_z(0.4)))
    m.add(box((0, 0, 0), (26, 4, 6), silver))
    # plica = hoja recta
    m.add(blade(105, 9, silver).apply(t=(0, 2, 0)))
    # corchete: gancho curvo que sale de la punta
    flag = []
    for i in range(10):
        t = i / 9
        flag.append((3 + 26 * t, 100 - 45 * t + 18 * math.sin(math.pi * t), 0))
    m.add(*tube(flag, 3.2, steel, 6, r_end=1.2))
    m.add(box((0, 55, 1.2), (1.0, 80, 0.6), glow))
    m.ground()
    return m


def make_filo_diapason():
    m = Model("Espada_FiloDiapason")
    gold = m.mat("laton", (0.95, 0.78, 0.30))
    steel = m.mat("hoja", (0.86, 0.88, 0.92))
    grip = m.mat("mango", (0.10, 0.30, 0.32))
    glow = m.mat("brillo", (0.55, 1.0, 0.85), emissive=True)
    hilt(m, 26, grip, gold)
    m.add(sphere(4.5, gold, 8, 6, center=(0, -29, 0)))
    m.add(box((0, 4, 0), (34, 8, 7), gold))
    for sx in (-1, 1):
        m.add(blade(90, 8, steel).apply(t=(sx * 11, 8, 0)))
        m.add(sphere(3, glow, 6, 4, center=(sx * 11, 8, 0)))
    m.add(torus(9, 1.5, glow, 12, 4).apply(m=rot_x(math.pi / 2), t=(0, 20, 0)))  # onda entre las hojas
    m.ground()
    return m


def make_campana_rota():
    m = Model("Espada_CampanaRota")
    bronze = m.mat("bronce", (0.62, 0.42, 0.22))
    steel = m.mat("hoja", (0.55, 0.52, 0.62))
    grip = m.mat("mango", (0.20, 0.16, 0.26))
    glow = m.mat("brillo", (0.70, 0.60, 1.0), emissive=True)
    hilt(m, 24, grip, bronze)
    # guarda: campana boca arriba, agrietada
    b = bell(22, bronze, 14).apply(m=rot_x(math.pi), t=(0, 18, 0))
    b.v[b.v[:, 0] > 8, 1] += 3  # borde partido
    m.add(b)
    m.add(blade(88, 10, steel, segs=4).apply(t=(0, 14, 0)))
    for i in range(3):  # grietas brillantes en la hoja
        m.add(box((0, 40 + i * 18, 1.4), (5, 1.2, 0.5), glow, m=rot_z(0.6 * (-1) ** i)))
    m.add(bell(8, bronze, 10).apply(t=(6, -34, 0)))  # campanilla colgando del pomo
    m.add(cylinder((0, -26, 0), (6, -26, 0), 0.6, bronze, segs=4))
    m.ground()
    return m


def make_batuta():
    m = Model("Espada_BatutaMayor")
    ivory = m.mat("marfil", (0.95, 0.93, 0.85))
    gold = m.mat("oro", (0.95, 0.75, 0.25))
    grip = m.mat("mango", (0.08, 0.08, 0.10))
    glow = m.mat("brillo", (1.0, 1.0, 0.85), emissive=True)
    m.add(lathe([(4.5, -30), (5.2, -24), (4, -6), (5, 0)], grip, 10))
    m.add(sphere(6, gold, 10, 6, center=(0, -32, 0)))
    m.add(torus(7, 1.6, gold, 12, 4).apply(t=(0, 1, 0)))
    m.add(lathe([(3.4, 0), (2.6, 60), (1.5, 110), (0.3, 125)], ivory, 10))
    for i in range(3):  # anillos de compás
        m.add(torus(3.0 - i * 0.6, 0.7, gold, 10, 4).apply(t=(0, 25 + i * 30, 0)))
    m.add(sphere(2.5, glow, 8, 6, center=(0, 125, 0)))
    m.ground()
    return m


# ---------------------------------------------------------------- enemigos (los Mudos)
def mudo_mats(m, glow_rgb=(0.55, 0.85, 1.0)):
    return (m.mat("piedra", (0.60, 0.60, 0.64)), m.mat("piedra_oscura", (0.32, 0.32, 0.37)),
            m.mat("brillo", glow_rgb, emissive=True))


def glow_eyes(m, glow, y, z, sep=10, r=4.0):
    for sx in (-1, 1):
        m.add(sphere(r, glow, 8, 5, center=(sx * sep, y, z), s=(1.2, 0.8, 0.5)))


def make_badajo():
    m = Model("Badajo")
    stone, dark, glow = mudo_mats(m, (1.0, 0.6, 0.25))
    bronze = m.mat("bronce", (0.55, 0.40, 0.25))
    m.add(bell(150, bronze, 16).apply(t=(0, 45, 0)))  # cuerpo-campana
    m.add(torus(92, 6, dark, 18, 5).apply(t=(0, 47, 0)))
    m.add(sphere(14, bronze, 10, 6, center=(0, 197, 0)))
    m.add(torus(10, 4, bronze, 10, 5).apply(m=rot_x(math.pi / 2), t=(0, 210, 0)))  # asa
    glow_eyes(m, glow, 140, 62, 18, 7)
    m.add(box((0, 112, 70), (40, 5, 6), glow, m=rot_x(-0.25)))  # boca-grieta
    # badajo colgando como pierna central / maza
    m.add(cylinder((0, 120, 0), (0, 25, 10), 7, dark, segs=8))
    m.add(sphere(22, dark, 10, 8, center=(0, 22, 12)))
    for sx in (-1, 1):  # patas cortas
        m.add(cylinder((sx * 50, 50, 0), (sx * 60, 0, 6), 14, stone, 18, segs=8))
        m.add(box((sx * 60, 5, 16), (34, 10, 40), stone))
    m.ground()
    return m


def make_coro_hueco():
    m = Model("CoroHueco")
    stone, dark, glow = mudo_mats(m, (0.75, 0.6, 1.0))
    void = m.mat("vacio", (0.03, 0.03, 0.05))
    m.add(lathe([(70, 0), (66, 14), (60, 18)], dark, 16))  # peana común
    for i, (x, z, h) in enumerate(((-38, -8, 150), (0, 12, 175), (38, -8, 150))):
        m.add(lathe([(26, 15), (24, 40), (17, h * 0.62), (13, h * 0.75)], stone, 12).apply(t=(x, 0, z)))
        hc = (x, h * 0.85, z)
        m.add(sphere(19, stone, 12, 8, center=hc, s=(1, 1.15, 1)))  # capucha
        m.add(cylinder((x, h * 0.95, z - 6), (x, h * 1.08, z - 16), 8, stone, 1.5, segs=8))
        m.add(sphere(9, void, 10, 6, center=(x, h * 0.82, z + 14), s=(0.9, 1.4, 0.5)))  # boca abierta "O"
        glow_eyes(m, glow, h * 0.9, z + 15, 7, 2.6)
        m.add(torus(13, 1.6, glow, 14, 4).apply(m=rot_x(math.pi / 2), t=(x, h * 0.82, z + 30)))  # nota cantada
    m.ground()
    return m


def make_sordina():
    m = Model("Sordina")
    stone, dark, glow = mudo_mats(m, (0.5, 1.0, 0.7))
    cloth = m.mat("vendas", (0.78, 0.74, 0.66))
    m.add(sphere(55, stone, 16, 10, center=(0, 60, 0), s=(1.1, 0.9, 1.0)))
    for i, y in enumerate((30, 50, 72, 92)):  # vendas que la amordazan
        m.add(torus(55 - abs(y - 60) * 0.45, 4, cloth, 18, 4).apply(m=rot_z(0.15 * (-1) ** i), t=(0, y, 0)))
    m.add(sphere(16, glow, 12, 8, center=(0, 78, 47), s=(1.2, 1, 0.5)))  # ojo único
    m.add(sphere(7, dark, 8, 6, center=(0, 78, 54), s=(1, 1, 0.4)))
    m.add(box((0, 50, 52), (60, 10, 6), cloth))  # mordaza
    for sx in (-1, 1):  # bracitos y patitas
        limb(m, (sx * 52, 70, 0), (sx * 78, 45, 18), 7, dark, 6)
        m.add(cylinder((sx * 25, 15, 0), (sx * 28, 0, 6), 10, dark, 12, segs=8))
    m.ground()
    return m


def make_yunque():
    m = Model("Yunque")
    stone, dark, glow = mudo_mats(m, (1.0, 0.45, 0.2))
    iron = m.mat("hierro", (0.25, 0.26, 0.30))
    # cuerpo: yunque (bloque + cuerno delantero)
    m.add(box((0, 150, 0), (120, 45, 70), iron))
    m.add(cylinder((0, 150, 35), (0, 150, 110), 22, iron, 2, segs=8))
    m.add(box((0, 110, 0), (70, 40, 50), dark))
    m.add(box((0, 85, 0), (100, 18, 60), iron))
    glow_eyes(m, glow, 160, 36, 22, 6)
    m.add(box((0, 135, 36), (60, 4, 3), glow))  # grieta-boca
    for sx in (-1, 1):  # piernas de piedra gruesas
        m.add(cylinder((sx * 32, 80, 0), (sx * 40, 0, 0), 22, stone, 26, segs=8))
        m.add(box((sx * 40, 7, 10), (55, 14, 70), stone))
    # brazo-martillo derecho y brazo izquierdo
    limb(m, (65, 150, 0), (95, 105, 25), 15, stone)
    m.add(cylinder((95, 105, 25), (100, 45, 45), 5, dark, segs=6))
    m.add(box((100, 40, 47), (55, 34, 34), iron))
    limb(m, (-65, 150, 0), (-92, 100, 20), 15, stone)
    m.add(sphere(20, stone, 10, 8, center=(-94, 92, 22)))
    m.ground()
    return m


def make_fuelle():
    m = Model("Fuelle")
    stone, dark, glow = mudo_mats(m, (0.7, 1.0, 1.0))
    leather = m.mat("cuero", (0.45, 0.30, 0.22))
    # cuerpo en pliegues de acordeón
    for i in range(6):
        r = 40 - abs(i - 2.5) * 5
        m.add(torus(r, 7, leather, 16, 5).apply(m=rot_x(math.pi / 2), t=(0, 90, -30 + i * 12)))
    m.add(cylinder((0, 90, -38), (0, 90, -46), 42, stone, segs=14).apply())
    m.add(cylinder((0, 90, 38), (0, 90, 48), 36, stone, segs=14))
    # hocico-boquilla
    m.add(cylinder((0, 90, 48), (0, 90, 95), 14, dark, 4, segs=10))
    m.add(torus(5, 2, glow, 10, 4).apply(m=rot_x(math.pi / 2), t=(0, 90, 96)))
    glow_eyes(m, glow, 108, 50, 16, 4)
    for sx in (-1, 1):  # alas de piedra
        wing = box((sx * 65, 115, -10), (70, 6, 40), stone, m=rot_z(sx * 0.5))
        m.add(wing)
    for i in range(3):  # ráfagas
        m.add(torus(10 + i * 6, 1.4, glow, 12, 4).apply(m=rot_x(math.pi / 2), t=(0, 90, 110 + i * 18)))
    m.ground()
    return m


def make_diapason():
    m = Model("Diapason")
    stone, dark, glow = mudo_mats(m, (0.6, 1.0, 0.8))
    metal = m.mat("metal", (0.72, 0.74, 0.80))
    m.add(lathe([(45, 0), (40, 10), (14, 30), (12, 70)], dark, 12))  # pie
    m.add(sphere(40, stone, 14, 10, center=(0, 105, 0)))  # cuerpo
    glow_eyes(m, glow, 112, 34, 14, 5)
    m.add(box((0, 135, 0), (70, 16, 26), metal))  # base de las púas
    for sx in (-1, 1):
        m.add(box((sx * 28, 195, 0), (16, 110, 18), metal))
        m.add(sphere(9, glow, 8, 6, center=(sx * 28, 252, 0)))
    for i, r in enumerate((30, 48, 66)):  # ondas de vibración
        m.add(torus(r, 1.6, glow, 20, 4).apply(t=(0, 190 + i * 12, 0)))
    for sx in (-1, 1):  # brazos finos
        limb(m, (sx * 38, 115, 0), (sx * 70, 80, 20), 6, dark, 5)
    m.ground()
    return m


def make_eco_errante():
    m = Model("EcoErrante")
    stone, dark, glow = mudo_mats(m, (0.55, 0.75, 1.0))
    mist = m.mat("niebla", (0.80, 0.84, 0.92))
    m.add(sphere(32, mist, 14, 10, center=(0, 120, 0)))
    m.add(sphere(14, glow, 10, 8, center=(0, 120, 20)))  # núcleo brillante
    glow_eyes(m, glow, 132, 28, 12, 4)
    for i in range(4):  # anillos de eco alrededor
        m.add(torus(42 + i * 12, 2.5 - i * 0.4, glow if i % 2 else mist, 20, 4)
              .apply(m=rot_x(0.4 + i * 0.25) @ rot_z(i * 0.6), t=(0, 120, 0)))
    tail = [(0, 95 - i * 18, -i * 10 - 5) for i in range(5)]  # cola de niebla
    m.add(*tube(tail, 20, mist, 10, r_end=3))
    for sx in (-1, 1):
        m.add(*tube([(sx * 28, 115, 0), (sx * 55, 100, 15), (sx * 65, 80, 30)], 7, mist, 8, r_end=3))
    m.ground()
    return m


def make_gargola():
    m = Model("GargolaCoral")
    stone, dark, glow = mudo_mats(m, (1.0, 0.5, 0.8))
    bronze = m.mat("bronce", (0.55, 0.40, 0.25))
    robe = m.mat("tunica_coral", (0.42, 0.36, 0.40))
    # cuerpo agachado con túnica de coro
    m.add(lathe([(55, 0), (50, 20), (45, 80), (40, 120), (24, 150)], robe, 14))
    m.add(sphere(36, stone, 12, 8, center=(0, 175, 18), s=(1, 0.9, 1.1)))  # cabeza adelantada
    for sx in (-1, 1):  # cuernos
        m.add(cylinder((sx * 22, 195, 10), (sx * 40, 235, -5), 8, dark, 1, segs=6))
    glow_eyes(m, glow, 180, 50, 14, 5)
    m.add(box((0, 158, 48), (34, 6, 6), dark))  # colmillos/boca
    # alas de esquirlas de campana
    for sx in (-1, 1):
        for i in range(4):
            a = 0.3 + i * 0.35
            base = np.array((sx * 30, 140, -25))
            tip = base + np.array((sx * (70 + i * 15) * math.cos(a), 40 + i * 25, -30))
            m.add(cylinder(base, tip, 14 - i * 2, bronze, 2, segs=4))
    # brazos con garras apoyadas en el suelo
    for sx in (-1, 1):
        limb(m, (sx * 40, 130, 15), (sx * 62, 70, 40), 12, stone)
        limb(m, (sx * 62, 70, 40), (sx * 60, 8, 55), 10, stone)
        for j in (-1, 0, 1):
            m.add(cylinder((sx * 60, 8, 55), (sx * 60 + j * 8, 0, 72), 3, dark, 1, segs=5))
    m.ground()
    return m


ENEMIES = [make_badajo, make_coro_hueco, make_sordina, make_yunque,
           make_fuelle, make_diapason, make_eco_errante, make_gargola]

MODELS = [make_oria, make_joel, make_kesh, make_metronomo, make_soprano,
          make_clave_sol, make_corchea, make_filo_diapason, make_campana_rota, make_batuta] + ENEMIES

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "Assets/Modelos"
    for make in MODELS:
        model = make()
        path = model.save(out)
        lo, hi = model.bounds()
        print(f"{model.name}: {model.tri_count()} triángulos, tamaño {np.round(hi - lo).astype(int)} cm -> {path}")
