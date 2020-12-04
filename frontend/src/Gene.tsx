/** Genes identified by a name, HUGO and Entrez ID. */
export type Gene = {
    name: string,
    hugo: string,
    entrez: string,
}

/** Expected shape by backend. */
export type GeneWithNumberEntrez = {
    name: string,
    hugo: string,
    entrez: number
}

/** Direction of test cases relative to threshold. */
export type Direction = "above" | "below";

/** Controls can be defined as mirrored to test threshold (mirrored), or opposite direction of test threshold (complement). */
export type ControlType = "mirrored" | "complement";

export type GeneConfig = {
    threshold: number, // stored in frontend in range 0-100, but needs to be converted to 0-1 before sending to backend
    direction: Direction,
    control: ControlType
}

export const defaultGeneThreshold: GeneConfig = {
    threshold: 50,
    direction: "above",
    control: "complement",
}

/** Convert to form expected by backend. */
export function convertGeneToBackendShape(gene: Gene) {
    return {
        name: gene.name,
        hugo: gene.hugo,
        entrez: parseInt(gene.entrez, 10),
    }
}