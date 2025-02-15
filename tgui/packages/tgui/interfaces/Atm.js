import { Window } from "../layouts";
import { AtmScreen } from "./Atm/index";
import { useBackend } from "../backend";
import { useContext } from "inferno";

const Atm = () => {
  const { act, data } = useBackend(useContext());

  return (
    <Window width={500} height={500} theme="light">
      <AtmScreen data={data} act={act} />
    </Window>
  );
};
