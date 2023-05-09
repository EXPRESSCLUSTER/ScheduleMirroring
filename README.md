# Fundamentals for schedule mirroring

This document describes the fundamental operation steps for configuring *schedule mirroring* on ECX 5.x.

---

## Premice

- `node1` is the hostname of Node1 and it is active node.
- `node2` is the hostname of Node2 and it is standby node.
- `md1`   is the name of the *mirror disk resource* and active on Node1.
- `mdw1`  is the name of the *mirror disk monitor resource*.

## Operations

1. Open `cmd.exe` on Node2.
2. Suspend `mdw1` (mirror disk watcher) to disable automatic recovery of the md (mirror disk) resource.

    ```
    clpmonctrl -s -h node1 -m mdw1
    clpmonctrl -s -h node2 -m mdw1
    ```

3. Stop `cluster server service`

    ```
    clpcl -t
    ```

4. Issue `Mirror break` on Node2.
    ```
    clpmdctrl --break md1
    ```
    <!--
    Ignore the error message `The status of md1 is invalid.` if it is displayed.
    -->

5. Issue `Active mirror disk` forcively on Node2.
    ```
    clpmdctrl --active md1 -f
    ```
6. Make operations on Node2.
   Changes on mirror disk `md1` will be lost when the mirror disk is resynchronized in a subsequent step.
   This step can last a long time.

7. Issue `Deactive mirror disk` forcively on Node2.
    ```
    clpmdctrl --deactive md1
   ```

8. Start `cluster server service`
    ```
    clpcl -s
    ```

9. Resume `mdw1` (mirror disk watcher) to enable automatic recovery of the md (mirror disk) resource. Resynchronization will be started automatically.

    ```
    clpmonctrl -r -h node2 -m mdw1
    clpmonctrl -r -h node1 -m mdw1
    ```
