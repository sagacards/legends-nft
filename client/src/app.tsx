import React from 'react';
import * as THREE from 'three';
import {
    Canvas,
    useLoader,
    createPortal,
    useThree,
    useFrame,
    GroupProps,
    ThreeEvent,
} from '@react-three/fiber';
import { useSpring, animated, useSpringRef } from "@react-spring/three";
import { animated as animatedWeb } from '@react-spring/web';
import { useDrag } from 'react-use-gesture';
import create from 'zustand';


//////////////////////////////
// Fetching Legends Assets //
////////////////////////////


// Types

type Tag = string;
type FilePath = string;
type Color = string;
interface LegendManifest {
    back: Tag;
    border: Tag;
    ink: Tag;
    maps: {
        normal: FilePath;
        layers: [FilePath];
        back: FilePath;
        border: FilePath;
        background: FilePath;
    };
    colors: {
        base: Color;
        specular: Color;
        emissive: Color;
    };
    views: {
        flat: FilePath;
        sideBySide: FilePath;
        animated: FilePath;
        interactive: FilePath;
    };
    nri: {
		back: number;
		border: number;
		ink: number;
		avg: number;
	};
};

// Fetching w/ react suspense
export const host = window.location.host.includes('localhost')
    ? `http://${window.location.host}`
    : `https://${window.location.host}`;
const index = (window as any).legendIndex || 0;
const promise = fetch(`${host}/legend-manifest/${index}/`).then(r => r.json());
function suspend<T>(promise: Promise<T>) {
    let result: T;
    let status = 'pending';

    const suspender = promise.then(response => {
        status = 'success';
        result = response;
    }, error => {
        status = 'error';
        result = error;
    });

    return function () {
        switch (status) {
            case 'pending':
                throw suspender;
            case 'error':
                throw result;
            default:
                return result;
        }
    };
}
const useLegendManifest = suspend<LegendManifest>(promise);

// Get normal map from canister.
function useLegendNormal(): THREE.Texture {
    const { maps: { normal } } = useLegendManifest();
    return useLoader(THREE.TextureLoader, `${host}${normal}`);
};

// Get card back alpha map from canister.
function useLegendBack(): THREE.Texture {
    const { maps: { back } } = useLegendManifest();
    return useLoader(THREE.TextureLoader, `${host}${back}`);
};

// Get card border alpha map from canister.
function useLegendBorder(): THREE.Texture {
    const { maps: { border } } = useLegendManifest();
    return useLoader(THREE.TextureLoader, `${host}${border}`);
};

// Get parallax layer textures from canister.
function useLegendLayers(): THREE.Texture[] {
    const { maps: { layers } } = useLegendManifest();
    return layers.map(layer => useLoader(THREE.TextureLoader, `${host}${layer}`));
};

// Get colors from canister.
function useLegendColors(): [THREE.Color, THREE.Color, THREE.Color] {
    const { colors: { base, specular, emissive } } = useLegendManifest();
    return [
        new THREE.Color(base).convertSRGBToLinear(),
        new THREE.Color(specular).convertSRGBToLinear(),
        new THREE.Color(emissive).convertSRGBToLinear(),
    ];
}


//////////////////////
// Card Primitives //
////////////////////


interface CardProps extends GroupProps {
    materials?: React.ReactNode;
}

function useCardGeometry() {
    const geometry = React.useRef<THREE.ShapeGeometry>(CardGeometry());
    return geometry.current;
}

function roundedRectFromDimensions(width: number, height: number, corners: number) {
    const shape = new THREE.Shape();
    const w = width / 2;
    const h = height / 2;
    const c = corners;
    shape.lineTo(-w, +h - c); // top left 1
    shape.bezierCurveTo(
        -w, +h,  // Control point should hit the real corner
        -w + c, +h,  // Last two pairs are what lineTo would have been
        -w + c, +h  ,
    ); // top left 2
    shape.lineTo(+w - c, +h); // top right 1
    shape.bezierCurveTo(
        +w, +h,
        +w, +h - c,
        +w, +h - c,
    ); // top right 2
    shape.lineTo(+w, -h + c); // bottom right 1
    shape.bezierCurveTo(
        +w, -h,
        +w - c, -h,
        +w - c, -h  ,
    ); // bottom right 2
    shape.lineTo(-w + c, -h); // bottom left 1
    shape.bezierCurveTo(
        -w, -h,
        -w, -h + c,
        -w, -h + c,
    ); // bottom left 2
    shape.lineTo(-w, +h - c); // close
    shape.autoClose = true;
    return shape;
};

function TarotCardShape() {
    return roundedRectFromDimensions(2.75, 4.75, .125);
};

function getDimensions(shape: THREE.Shape) {
    return shape.curves.reduce((range, curve) => [
        [
            Math.min(range[0][0], curve.getPoint(0).x, curve.getPoint(0).x),
            Math.max(range[0][1], curve.getPoint(0).x, curve.getPoint(0).x)
        ],
        [
            Math.min(range[1][0], curve.getPoint(0).y, curve.getPoint(0).y),
            Math.max(range[1][1], curve.getPoint(0).y, curve.getPoint(0).y)
        ],
    ], [[0, 0], [0, 0]]).map((x) => Math.abs(x[0]) + Math.abs(x[1])) as [number, number];
};

export function CardUVGenerator(shape: THREE.Shape, offset = [0, 0, 0, 0]) {
    const [w, h] = getDimensions(shape);
    const b = [
        [-w / 2 + offset[0], -h / 2 + offset[0]],
        [+w / 2, +h / 2],
    ];
    return {
        generateTopUV: function (
            geometry: THREE.ExtrudeGeometry,
            vertices: number[],
            indexA: number,
            indexB: number,
            indexC: number
        ) {

            const ax = vertices[indexA * 3];
            const ay = vertices[indexA * 3 + 1];
            const bx = vertices[indexB * 3];
            const by = vertices[indexB * 3 + 1];
            const cx = vertices[indexC * 3];
            const cy = vertices[indexC * 3 + 1];

            return [
                new THREE.Vector2((ax - b[0][0]) / (w - (offset[0] + offset[2])), (ay - b[0][1]) / (h - (offset[1] + offset[2]))),
                new THREE.Vector2((bx - b[0][0]) / (w - (offset[0] + offset[2])), (by - b[0][1]) / (h - (offset[1] + offset[2]))),
                new THREE.Vector2((cx - b[0][0]) / (w - (offset[0] + offset[2])), (cy - b[0][1]) / (h - (offset[1] + offset[2]))),
            ];
        },

        generateSideWallUV: function (
            geometry: THREE.ExtrudeGeometry,
            vertices: number[],
            indexA: number,
            indexB: number,
            indexC: number,
            indexD: number
        ) {
            // We don't give a hoot about card edges
            return [
                new THREE.Vector2(0, 0),
                new THREE.Vector2(0, 0),
                new THREE.Vector2(0, 0),
                new THREE.Vector2(0, 0),
            ];
        }
    }
};

function CardGeometry(shape: THREE.Shape = TarotCardShape()) {
    const geometry = new THREE.ExtrudeGeometry(shape, {
        bevelEnabled: false,
        depth: .025,
        steps: 1,
        UVGenerator: CardUVGenerator(shape),
    });

    // Break the geometry into front, back and side groups for texturing.
    geometry.clearGroups();
    let groupCount = [0, 0, 0];
    let groupStart: (number | undefined)[] = [undefined, undefined, undefined];
    for (let i = 1; i <= geometry.attributes.normal.count; i++) {
        const index = 2 + ((3 * i) - 3);
        const vIndex = i - 1;
        const z = geometry.attributes.normal.array[index];

        switch (z) {
            case 1: groupCount[0]++;
                groupStart[0] = groupStart[0] == null ? vIndex : groupStart[0];
                break;  // Front
            case 0: groupCount[1]++;
                groupStart[1] = groupStart[1] == null ? vIndex : groupStart[1];
                break;  // Side
            case -1: groupCount[2]++;
                groupStart[2] = groupStart[2] == null ? vIndex : groupStart[2];
                break;  // Back

        }
    }
    geometry.addGroup(groupStart[0] as number, groupCount[0], 2);
    geometry.addGroup(groupStart[1] as number, groupCount[1], 1);
    geometry.addGroup(groupStart[2] as number, groupCount[2], 0);

    return geometry;
}

function Card({
    materials,
    ...props
}: CardProps) {
    const geometry = useCardGeometry();
    return <>
        <group>
            <group {...props}>
                <mesh geometry={geometry}>
                    {materials || <meshPhongMaterial color={"#000"} />}
                </mesh>
                {props.children}
            </group>
        </group>
    </>
};


///////////////
// Card Ink //
/////////////


interface CardInkProps {
    colorBase: THREE.Color;
    colorSpecular: THREE.Color;
    colorEmissive: THREE.Color;
};

export function CardBackInk(props: CardInkProps) {
    const texture = React.useMemo(() => useLegendBack(), []);
    const normal = React.useMemo(() => useLegendNormal(), []);
    return (
        <mesh position={[0, 0, -0.026]}>
            <planeGeometry args={[2.74, 4.75]} />
            <meshPhongMaterial
                side={THREE.BackSide}
                alphaMap={texture}
                transparent={true}
                color={props.colorBase}
                emissive={props.colorEmissive}
                emissiveIntensity={0.125}
                specular={props.colorSpecular}
                shininess={200}
                normalMap={normal}
                // @ts-ignore
                normalScale={[0.05, 0.05]}
            />
        </mesh>
    );
}

export function CardBorderInk(props: CardInkProps) {
    const texture = React.useMemo(() => useLegendBorder(), []);
    const normal = React.useMemo(() => useLegendNormal(), []);
    return (
        <>
            <mesh position={[0, 0, 0.0265]}>
                <planeGeometry args={[2.74, 4.75]} />
                <meshPhongMaterial
                    alphaMap={texture}
                    transparent={true}
                    color={props.colorBase}
                    emissive={props.colorEmissive}
                    emissiveIntensity={0.125}
                    specular={props.colorSpecular}
                    shininess={200}
                    normalMap={normal}
                    // @ts-ignore
                    normalScale={[0.05, 0.05]}
                />
            </mesh>
        </>
    );
};


////////////////////////
// The Parallax Card //
//////////////////////


const d = [2681, 4191]; // Dimensions of the art assets
const e = 1.41 / 1000; // Factor to normalize art assets to tarot card dimensions
const f = [2.75, 4.75]; // Tarot card dimensions
    
// Layers comprising the card face, layed out on the Z axis.
function CardArt(props: { textures: THREE.Texture[] }) {
    const geometry = React.useMemo(() => new THREE.PlaneGeometry(d[0] * e, d[1] * e), []);
    return (
        <group>
            {props.textures.map((t, i) => <mesh position={[0, 0, (-20 / props.textures.length) * i]} key={`tex${i}`} geometry={geometry}>
                <meshStandardMaterial transparent={true} map={t} />
            </mesh>)}
            <ambientLight intensity={0.5} />
        </group>
    );
};

// Renders card art onto card mesh using default camera and a portal to create the depth effect.
function LegendCard({ rotation, ...props }: GroupProps) {

    // Legends traits
    const [colorBase, colorSpecular, colorEmissive] = React.useMemo(useLegendColors, []);
    const normal = React.useMemo(() => useLegendNormal(), []);

    // Refs
    const scene = React.useRef(new THREE.Scene());
    const target = React.useRef(new THREE.WebGLRenderTarget(d[0], d[1]));
    const camera = React.useRef(new THREE.OrthographicCamera(-f[0] / 2, f[0] / 2, f[1] / 2, -f[1] / 2));
    React.useEffect(() => void (camera.current.position.z = 20), []);
    const mesh = React.useRef<THREE.Group>();
    const clock = React.useRef({
        tick: 0,
        lastTick: 0,
        tps: 10,
        elapsed: 0,
        prevElapsed: 0,
        animOffset: 0,
        slowFrames: 0,
    });
    const mouse = React.useRef({
        x: 0,
        y: 0,
        hover: false
    })

    // State
    const [flip, setFlip] = React.useState(false);

    // Animation
    const { accelerometer } = useStore();
    const acceleration = accelerometer.createRef();
    const spring = useSpringRef();
    const rotDeviceTilt = [
        THREE.MathUtils.clamp(acceleration.current.alpha, -10, 10) / 10 * Math.PI * .025,
        THREE.MathUtils.clamp(acceleration.current.beta, -10, 10) / 10 * Math.PI * .1,
        THREE.MathUtils.clamp(acceleration.current.gamma, -10, 10) / 10 * Math.PI * .01,
    ];
    const springProps = useSpring({
        ref: spring,
        rotation: [
            THREE.MathUtils.degToRad(0 + mouse.current.y * 5),
            (flip ? 0 : Math.PI) - THREE.MathUtils.degToRad(mouse.current.x * 5),
            0
        ] as unknown as THREE.Vector3,
        position: [0, 0, mouse.current.hover ? 0.1 : 0] as unknown as THREE.Euler,
        config: {
            mass: 10,
            tension: 300,
            friction: 85
        }
    });
    const hoverBox = React.useMemo(() => new THREE.Box3(), []);
    function hoverTilt(e: ThreeEvent<PointerEvent>) {
        hoverBox.setFromObject(e.eventObject);
        mouse.current.x = e.point.x >= 0 ? e.point.x / hoverBox.max.x : -e.point.x / hoverBox.min.x;
        mouse.current.y = e.point.y >= 0 ? e.point.y / hoverBox.max.y : -e.point.y / hoverBox.min.y;
    }
    const cardProps = {
        ...springProps,
        onPointerMove: hoverTilt,
        onPointerEnter: () => mouse.current.hover = true,
        onPointerLeave: () => {
            mouse.current.hover = false;
            mouse.current.x = 0;
            mouse.current.y = 0;
        },
        onClick: () => {
            setFlip(!flip);
        },
    };

    // Configure performance regression
    const { regress } = useThree(state => ({
        regress: state.performance.regress,
        performance: state.performance.current
    }));

    useFrame((state) => {
        if (!mesh.current) return;

        // Update clock
        const t = state.clock.getElapsedTime();
        const c = clock.current;
        c.prevElapsed = c.elapsed;
        c.elapsed = t;

        // Regress quality based on subsequent slow frame renders
        const fps = 1 / (c.elapsed - c.prevElapsed);
        if (fps < 15) {
            c.slowFrames++;
            regress();
        } else {
            c.slowFrames = 0;
        }

        // Dynamically set pixel density based on performance
        if (state.performance.current < 1) {
            state.setDpr(1);
        } else {
            state.setDpr(window.devicePixelRatio);
        }

        // Position camera
        const ry = mesh.current.rotation.y % Math.PI;
        const cy = THREE.MathUtils.clamp(
            ry > Math.PI / 2 ? ry - Math.PI : ry,
            -Math.PI,
            Math.PI
        ) / Math.PI;
        camera.current.position.x = -cy * 4 / 2;
        camera.current.lookAt(0, 0, 0);

        // Animate
        spring.start({
            rotation: ([
                THREE.MathUtils.degToRad(0 + mouse.current.y * 5) + rotDeviceTilt[0],
                (flip ? 0 : Math.PI) - THREE.MathUtils.degToRad(mouse.current.x * 5) + rotDeviceTilt[1],
                0 + rotDeviceTilt[2]
            ] as unknown) as THREE.Vector3,
            position: ([0, 0, mouse.current.hover ? 0.1 : 0] as unknown) as THREE.Euler,
            config: {
                mass: 30,
                tension: 300,
                friction: 100
            }
        });

        // Render
        state.gl.setRenderTarget(target.current);
        state.gl.render(scene.current, camera.current);
        state.gl.setRenderTarget(null);
    });

    return (
        <animated.group {...props} {...cardProps} ref={mesh}>
            {createPortal(<CardArt textures={useLegendLayers()} />, scene.current)}
            <Card
                materials={<>
                    <meshStandardMaterial attachArray="material" color={"#111"} />
                    <meshPhongMaterial
                        attachArray="material"
                        color={colorBase}
                        emissive={colorEmissive}
                        emissiveIntensity={0.125}
                        specular={colorSpecular}
                        shininess={200}
                        normalMap={normal}
                        // @ts-ignore
                        normalScale={[0.03, 0.03]}
                    />
                    <meshStandardMaterial
                        blending={THREE.NormalBlending}
                        attachArray="material"
                        map={target.current.texture}
                    />
                </>}
                children={<>
                    <CardBorderInk
                        colorBase={colorBase}
                        colorEmissive={colorEmissive}
                        colorSpecular={colorSpecular}
                    />
                    <CardBackInk
                        colorBase={colorBase}
                        colorEmissive={colorEmissive}
                        colorSpecular={colorSpecular}
                    />
                </>}
            />
        </animated.group>
    );
};


///////////////////
// Lighting Rig //
/////////////////


const center = new THREE.Object3D();
center.position.x = 0;
center.position.y = 0;
center.position.z = 0;

function Light() {
    return <>
        <directionalLight
            intensity={.5}
            position={[0, 0.15, 1]}
            target={center}
        />
        <directionalLight
            intensity={.25}
            position={[1, -1, 2]}
            target={center}
        />
        <directionalLight
            intensity={.25}
            position={[-1, -1, 2]}
            target={center}
        />
        <directionalLight
            intensity={.125}
            position={[1, 3, 1]}
            target={center}
        />
        <directionalLight
            intensity={.125}
            position={[-1, 3, 1]}
            target={center}
        />
        <directionalLight
            intensity={.25}
            position={[1, 0, 0]}
            target={center}
        />
        <directionalLight
            intensity={.25}
            position={[-1, 0, 0]}
            target={center}
        />
    </>
}


////////////////////
// Accelerometer //
//////////////////


interface Acceleration {
    // https://developers.google.com/web/fundamentals/native-hardware/device-orientation#device_motion
    x: number,
    y: number,
    z: number,
    beta: number,
    gamma: number,
    alpha: number,
};

interface Accelerometer {
    isSupported: boolean;
    permission: undefined | 'pending' | 'granted' | 'denied' | 'NA';
    createRef: () => React.MutableRefObject<Acceleration>,
    requestPermission: () => void,
};

interface Store {
    accelerometer: Accelerometer;
}

interface ToastProps {
    accept: () => void;
    dismiss: () => void;
    open: boolean;
};


///////////////////////
// Permission Toast //
/////////////////////


const PermissionToast:React.FC<ToastProps> = ({accept, dismiss, open}) => {
    const initial = { x: 0, y: 100, rotateZ: '-10deg', };
    const current = { x: 0, y: open ? -100 : 100, rotateZ: '0deg', };
    const springConf = { mass: 5, tension: 500, friction: 75 };
    const [{ x, y, rotateZ }, set] = useSpring(() => ({ ...initial, config: springConf }));

    set(current);

    const bind = useDrag(({ down, movement: [mX, mY], velocity, direction: [dX, dY], tap }) => {
        set({ x: down ? mX : current.x, y: down ? mY + current.y : current.y });
        if (velocity > .25 && dY === 1) {
            dismiss();
        }
        if (tap) {
            accept();
        }
    });

    return (
        <div className="toast-root">
            <animatedWeb.div className="toast" {...bind()} style={{ x, y, rotateZ, touchAction: 'none' }}>
                <div>Tap to enhance with your phone's accelerometer</div>
            </animatedWeb.div>
        </div>
    );
}


////////////////////////////
// The Application Store //
//////////////////////////


function useStore() {

    const refs = React.useRef<React.MutableRefObject<Acceleration>[]>([]);

    const ingestMotion = (e: DeviceMotionEvent) => {
        requestAnimationFrame(() => {
            for (const ref of refs.current) {
                ref.current.x = e.acceleration?.x || 0;
                ref.current.y = e.acceleration?.y || 0;
                ref.current.z = e.acceleration?.z || 0;
                ref.current.beta = e.rotationRate?.beta || 0;
                ref.current.gamma = e.rotationRate?.gamma || 0;
                ref.current.alpha = e.rotationRate?.alpha || 0;
            }
        });
    };

    const bindMotionEvents = React.useCallback(() => window.addEventListener('devicemotion', ingestMotion, false), []);
    const unbindMotionEvents = React.useCallback(() => window.removeEventListener('devicemotion', ingestMotion), []);

    React.useEffect(() => {
        bindMotionEvents();
        return unbindMotionEvents;
    }, []);

    const bindRef = React.useCallback((ref: React.MutableRefObject<Acceleration>) => {
        refs.current.push(ref);
    }, []);

    const createRef = React.useCallback(() => {
        const ref = React.useRef<Acceleration>({
            x: 0,
            y: 0,
            z: 0,
            beta: 0,
            gamma: 0,
            alpha: 0,
        });
        bindRef(ref);
        return ref;
    }, []);

    const store = create<Store>((set, get) => ({
        accelerometer: {
            createRef,
            isSupported: false,
            permission: undefined,
            requestPermission: () => {
                //@ts-ignore
                DeviceMotionEvent.requestPermission()
                //@ts-ignore
                .then(response => {
                    if (response === 'granted') {
                        bindMotionEvents();
                        set({ accelerometer: { ...get().accelerometer, permission: 'granted' }});
                    } else if (response === 'denied') {
                        set({ accelerometer: { ...get().accelerometer, permission: 'denied' }});
                    }
                })
                .catch(console.error);
            }
        }
    }));
    return store();
}


///////////////
// App Root //
/////////////


// Loading state

function Loader () {
    return <div style={{width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'sans-serif'}}>Loading...</div>
}

function Loader3 () {
    const mesh = React.useRef<THREE.Mesh>();
    const light = React.useRef<THREE.DirectionalLight>();
    const center = React.useMemo(() => {
        const c = new THREE.Object3D;
        c.position.x = 0;
        c.position.y = 0;
        c.position.z = 0;
        return c
    }, []);
    const colors = React.useMemo(() => [
        new THREE.Color('#766007').convertSRGBToLinear(),
        new THREE.Color('#c1ab59').convertSRGBToLinear(),
        new THREE.Color('#c1ab59').convertSRGBToLinear(),
    ], []);
    useFrame(state => {
        if (!mesh.current || !light.current) return;
        mesh.current.position.y = Math.sin(state.clock.getElapsedTime() * 8) / 2;
        mesh.current.position.x = Math.cos(state.clock.getElapsedTime() * 8) / 2;
        light.current.lookAt(center.position);
    });
    return <mesh ref={mesh}>
        <sphereGeometry args={[.125]} />
        <meshStandardMaterial
            color={colors[0]}
            emissive={colors[1]}
            emissiveIntensity={0.125}
            metalness={7}
        />
        <directionalLight
            ref={light}
            target={center}
            position={[0, 0, 3]}
        />
        {/* <ambientLight intensity={.05} /> */}
    </mesh>
}

// Main canvas

function LegendPreviewCanvas() {
    const { views : { flat, sideBySide, animated}, back, border, ink, nri } = useLegendManifest();
    return (
        <div className="canvasContainer" style={{ width: '100%', height: '100%' }}>
            <div className="stats-1">
                <div>Mint: #{(window as any).legendIndex || 0}</div>
                <div>Back: {back} (NRI {Math.floor(nri.back * 100)}%)</div>
                <div>Border: {border} (NRI {Math.floor(nri.border * 100)}%)</div>
                <div>Ink: {ink} (NRI {Math.floor(nri.ink * 100)}%)</div>
                <div>Average NRI: {Math.floor(nri.avg * 100)}%</div>
            </div>
            <div className="stats-2">
                <a href={sideBySide}>Static View</a>
                <a href={animated}>Animated View</a>
            </div>
            <Canvas
                dpr={window.devicePixelRatio}
                performance={{ min: .1, max: 1, debounce: 10000 }}
                mode="concurrent"
            >
                <React.Suspense fallback={<Loader3 />}>
                    <LegendCard />
                    <Light />
                </React.Suspense>
            </Canvas>
        </div>
    );
}

// App root

export default function App() {
    const [toast, setToast] = React.useState(false);
    const { accelerometer: { permission, requestPermission } } = useStore();
    React.useEffect(() => {
        // @ts-ignore
        if (typeof window.DeviceMotionEvent?.requestPermission === 'function') {
            // @ts-ignore
            DeviceMotionEvent?.requestPermission()
            // @ts-ignore
            .then((r) => {
                if (r !== 'granted') setToast(true);
            })
            // @ts-ignore
            .catch((r) => setToast(true));
        }
    }, [permission]);
    const acceptToast = () => {
        requestPermission();
        setToast(false);
    };

    const dismissToast = () => {
        setToast(false);
    }
    return <div style={{ width: '100vw', height: '100vh', overflow: 'hidden' }}>
        <PermissionToast accept={acceptToast} dismiss={dismissToast} open={toast} />
        <React.Suspense fallback={<Loader />}>
            <div style={{ width: '100%', height: '100%' }}>
                <LegendPreviewCanvas />
            </div>
        </React.Suspense>
    </div>
};

