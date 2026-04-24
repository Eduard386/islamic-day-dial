export function DalilOrnamentalDivider() {
  return (
    <div className="desktop-dalil-divider" aria-hidden>
      <span className="desktop-dalil-divider-line" />
      <span className="desktop-dalil-divider-dot" />
      <img
        className="desktop-dalil-divider-rosette"
        src={`${import.meta.env.BASE_URL}hijri-ornament-divider.png`}
        alt=""
        width={28}
        height={28}
        decoding="async"
      />
      <span className="desktop-dalil-divider-dot" />
      <span className="desktop-dalil-divider-line" />
    </div>
  );
}
