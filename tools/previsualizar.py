# previsualizar.py — Renderiza vistas (frente y lado) de los OBJ generados en PNG.
import sys, os, glob
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection


def load(obj):
    folder = os.path.dirname(obj)
    mats, cur = {}, None
    mtl = obj[:-4] + ".mtl"
    for line in open(mtl):
        p = line.split()
        if not p: continue
        if p[0] == "newmtl": cur = p[1]
        elif p[0] == "Kd": mats[cur] = tuple(float(x) for x in p[1:4])
    v, faces, mat = [], [], None
    for line in open(obj):
        p = line.split()
        if not p: continue
        if p[0] == "v":
            a, b, c = (float(x) for x in p[1:4])
            v.append([b, c, a])  # deshace el orden de ejes pensado para UEFN
        elif p[0] == "usemtl": mat = p[1]
        elif p[0] == "f": faces.append(([int(x) - 1 for x in p[1:]], mats.get(mat, (0.7, 0.7, 0.7))))
    return np.array(v), faces


def render(obj, png):
    v, faces = load(obj)
    fig = plt.figure(figsize=(10, 5.5), dpi=90)
    light = np.array([0.4, 0.8, 0.6]); light /= np.linalg.norm(light)
    for i, (elev, azim, title) in enumerate(((10, 90, "frente"), (10, 0, "lado"), (30, 50, "3/4"))):
        ax = fig.add_subplot(1, 3, i + 1, projection="3d")
        polys, cols = [], []
        for idx, rgb in faces:
            pts = v[idx][:, [0, 2, 1]]  # Y arriba -> Z de matplotlib
            n = np.cross(pts[1] - pts[0], pts[2] - pts[0])
            ln = np.linalg.norm(n)
            shade = 0.55 + 0.45 * abs(np.dot(n / ln, light[[0, 2, 1]])) if ln > 0 else 0.8
            polys.append(pts); cols.append(np.clip(np.array(rgb) * shade, 0, 1))
        pc = Poly3DCollection(polys, facecolors=cols, edgecolors="none")
        ax.add_collection3d(pc)
        lo, hi = v.min(0), v.max(0); c = (lo + hi) / 2; r = (hi - lo).max() / 2
        ax.set_xlim(c[0] - r, c[0] + r); ax.set_ylim(c[2] - r, c[2] + r); ax.set_zlim(c[1] - r, c[1] + r)
        ax.view_init(elev, azim); ax.set_axis_off(); ax.set_title(title)
    fig.suptitle(os.path.basename(obj)[:-4])
    fig.tight_layout(); fig.savefig(png); plt.close(fig)


if __name__ == "__main__":
    folder = sys.argv[1]
    for obj in sorted(glob.glob(os.path.join(folder, "*.obj"))):
        render(obj, obj[:-4] + "_vista.png")
        print("ok", obj)
