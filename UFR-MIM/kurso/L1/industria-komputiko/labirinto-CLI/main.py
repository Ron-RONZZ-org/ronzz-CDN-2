import os
import sys
from collections import deque


def getch():
    """Read a single character from stdin without requiring Enter."""
    try:
        import tty
        import termios

        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        return ch
    except Exception:
        # Fallback for Windows
        try:
            import msvcrt

            ch = msvcrt.getch()
            if isinstance(ch, bytes):
                return ch.decode("utf-8", errors="ignore")
            return ch
        except Exception:
            # As a last resort, fall back to normal input (requires Enter)
            return sys.stdin.read(1)


# --- Mapo-legendo ---
# '#' = muro
# '.' = vojo
# 'P' = ludanto komenca pozicio
# 'E' = malamiko
# 'T' = trezoro
# 'O' = elirejo

LEVEL_MAP = [
    "########################",
    "#P....#.......T....#..O#",
    "#.##..#..####..###.#..##",
    "#..T..#..#..E..#...#...#",
    "###.####.#.####.#.###..#",
    "#......T.#......#...T..#",
    "#.######.########.######",
    "#....E...#.......#.....#",
    "#.#######.#.######.###.#",
    "#...T....#....E...#....#",
    "########################",
]

ROWS = len(LEVEL_MAP)
COLS = len(LEVEL_MAP[0])


def clear_screen():
    os.system("clear" if os.name != "nt" else "cls")


def find_positions(char):
    positions = []
    for r, row in enumerate(LEVEL_MAP):
        for c, ch in enumerate(row):
            if ch == char:
                positions.append((r, c))
    return positions


player_pos = find_positions("P")[0]
enemy_positions = find_positions("E")
treasure_positions = set(find_positions("T"))
exit_positions = set(find_positions("O"))

# Interna krado sen specialaj signoj
grid = []
for r, row in enumerate(LEVEL_MAP):
    new_row = []
    for c, ch in enumerate(row):
        if ch in ["P", "E", "T", "O"]:
            new_row.append(".")
        else:
            new_row.append(ch)
    grid.append(new_row)


def is_walkable(r, c):
    if 0 <= r < ROWS and 0 <= c < COLS:
        return grid[r][c] != "#"
    return False


def bfs_next_step(start, goal):
    """Simpla BFS por trovi sekvan paŝon de start al goal."""
    if start == goal:
        return start

    queue = deque()
    queue.append(start)
    visited = {start: None}

    while queue:
        r, c = queue.popleft()
        if (r, c) == goal:
            break
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = r + dr, c + dc
            if is_walkable(nr, nc) and (nr, nc) not in visited:
                visited[(nr, nc)] = (r, c)
                queue.append((nr, nc))

    if goal not in visited:
        return start

    path = []
    cur = goal
    while cur is not None:
        path.append(cur)
        cur = visited[cur]
    path.reverse()

    if len(path) > 1:
        return path[1]
    else:
        return start


def move_enemies():
    global enemy_positions
    new_positions = []
    for er, ec in enemy_positions:
        nr, nc = bfs_next_step((er, ec), player_pos)
        new_positions.append((nr, nc))
    enemy_positions = new_positions


def check_state():
    # Malvenko se malamiko tuŝas la ludanton
    if player_pos in enemy_positions:
        return "lose"
    # Venko se ĉiuj trezoroj kolektitaj kaj ludanto sur elirejo
    if not treasure_positions and player_pos in exit_positions:
        return "win"
    return None


def draw():
    clear_screen()
    print("Labirinta ludo (1/2/3/4 por moviĝi, x por eliri)")
    print("Kolektu ĉiujn T kaj iru al O. Evitu E.\n")

    for r in range(ROWS):
        row_chars = []
        for c in range(COLS):
            ch = grid[r][c]
            pos = (r, c)

            if pos == player_pos:
                row_chars.append("P")
            elif pos in enemy_positions:
                row_chars.append("E")
            elif pos in treasure_positions:
                row_chars.append("T")
            elif pos in exit_positions:
                row_chars.append("O")
            else:
                row_chars.append(ch)
        print("".join(row_chars))

    print(f"\nRestantaj trezoroj: {len(treasure_positions)}")


def main():
    global player_pos

    while True:
        draw()
        state = check_state()
        if state == "win":
            print("\nVi gajnis! Gratulojn!")
            break
        elif state == "lose":
            print("\nVi perdis! Malamiko kaptis vin.")
            break

        # Lire une seule touche sans besoin d'appuyer sur Entrée
        print("\nVia movo (1/2/3/4, x por eliri): ", end="", flush=True)
        ch = getch()
        # Echo the key so user sees what they pressed
        try:
            # Some terminals may return empty or control characters; guard printing
            if ch:
                print(ch)
        except Exception:
            pass

        cmd = (ch or "").lower()
        if cmd == "x":
            print("Adiaŭ!")
            break

        dr, dc = 0, 0
        # Mapping: 1 = up, 2 = down, 3 = left, 4 = right
        if cmd == "1":
            dr = -1
        elif cmd == "2":
            dr = 1
        elif cmd == "3":
            dc = -1
        elif cmd == "4":
            dc = 1
        else:
            continue  # nekonata komando, simple redoni turnon

        pr, pc = player_pos
        nr, nc = pr + dr, pc + dc
        if is_walkable(nr, nc):
            player_pos = (nr, nc)
            # Kolekti trezoron
            if player_pos in treasure_positions:
                treasure_positions.remove(player_pos)

        # Post movo de ludanto, movi malamikojn
        move_enemies()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrompite.")
        sys.exit(0)
