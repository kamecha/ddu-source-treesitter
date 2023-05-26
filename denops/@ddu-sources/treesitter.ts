import {
  BaseSource,
  Context,
  Item,
} from "https://deno.land/x/ddu_vim@v2.5.0/types.ts";
import { ActionData } from "https://deno.land/x/ddu_kind_file@v0.4.0/file.ts";
import {
  ensureBoolean,
} from "https://deno.land/x/unknownutil@v2.1.0/ensure.ts";
import { Denops } from "https://deno.land/x/ddu_vim@v2.5.0/deps.ts";

type Params = Record<never, never>;

type TreeSitterDefinition = {
  name: string;
  kind: string;
  start: [number, number, number];
};

export class Source extends BaseSource<Params> {
  kind = "file";
  gather(args: {
    denops: Denops;
    context: Context;
  }): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream({
      async start(controller) {
        // check if treesitter is available
        if (
          !ensureBoolean(
            await args.denops.eval(
              `luaeval("require('ddu-source-treesitter').is_plugin_installed('nvim-treesitter')")`,
            ),
          )
        ) {
          controller.close();
          return;
        }

        const bufNr = args.context.bufNr;

        // check if parser is available
        if (
          !ensureBoolean(
            await args.denops.eval(
              `luaeval("require('ddu-source-treesitter').is_parser_installed(${bufNr})")`,
            ),
          )
        ) {
          controller.close();
          return;
        }

        // get definitions
        const defs = await args.denops.eval(
          `luaeval("require('ddu-source-treesitter').get_definitions(${bufNr})")`,
        ) as TreeSitterDefinition[];
        const items: Item<ActionData>[] = [];
        for (const def of defs) {
          try {
            items.push({
              word: `${def.name} ${def.kind}`,
              action: {
                bufNr: bufNr,
                lineNr: def.start[0] + 1,
              },
            });
          } catch (e) {
            console.log(e);
          }
        }
        controller.enqueue(items);
        controller.close();
      },
    });
  }
  params(): Params {
    return {};
  }
}
